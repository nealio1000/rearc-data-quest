package com.neal.rearc_quest

import org.apache.spark.sql._
import org.apache.spark.sql.functions._
import org.apache.spark.sql.types._
import com.typesafe.scalalogging.LazyLogging
import org.apache.spark.Partitioner

object RearcSparkJob extends LazyLogging {

    def main(args: Array[String]): Unit = {
        val spark = SparkSession.builder
            .master("local[*]")
            .appName("Rearc Spark Job")
            .config("spark.hadoop.fs.s3a.impl", "org.apache.hadoop.fs.s3a.S3AFileSystem")
            .getOrCreate()

        import spark.implicits._

        spark.conf.set("spark.sql.caseSensitive", true)

        try {
            // read in bls file time series data
            val blsSchema = StructType(Array(
                StructField("series_id", StringType, nullable = false),
                StructField("year", IntegerType, nullable = false),
                StructField("period", StringType, nullable = false),
                StructField("value", DoubleType, nullable = false),
                StructField("footnote_codes", StringType, nullable = true),
            ))

            val blsDf = spark.read
                .option("header", "true")
                .option("delimiter", "\t")
                .schema(blsSchema)
                .csv("s3a://rearc-quest-data-bucket/bls-data/pr.data.0.Current")

            // read in population data
            val populationDf = spark.read
                .option("multiline", "true")
                .json("s3a://rearc-quest-data-bucket/population/population.json")
                .withColumn("exploded_value", explode(col("data")))
                .select(
                    col("exploded_value.Year").cast(IntegerType).as("year"),
                    col("exploded_value.Population").cast(LongType).as("population")
                )

            // DataFrame #1
            val populationMeanAndStdDf = populationDf
                .filter(col("year") >= 2013 && col("year") <= 2018)
                .select(avg("population").as("Population Mean"), stddev("population").as("Population Standard Deviation"))

            // DataFrame #2
            val bestYearsDf = blsDf
                .groupBy(col("series_id"), col("year"))
                .agg(sum("value").as("total_value"))
                .orderBy(col("series_id"), col("year"))
                .groupBy(col("series_id"))
                .agg(max(struct(col("total_value"), col("year"))).as("year_value"))
                .select(col("series_id"), col("year_value.year").as("year"), col("year_value.total_value").as("value"))

            // Pre filter bls data before join
            val filteredBlsDf = blsDf
                .withColumn("series_id", trim(col("series_id")))
                .withColumn("period", trim(col("period")))
                .filter(
                    col("series_id") === "PRS30006032" && 
                    col("period") === "Q01"
                )
                .select("series_id", "year", "period", "value")


            // DataFrame #3
            val populationReportDf = filteredBlsDf
                .join(populationDf, filteredBlsDf("year") === populationDf("year"), "left")
                .filter(populationDf("population").isNotNull)
                .select(
                    filteredBlsDf("series_id"), 
                    filteredBlsDf("year"), 
                    filteredBlsDf("period"), 
                    filteredBlsDf("value"), 
                    populationDf("population").as("Population")
                )
                
            val baseS3Path = "s3a://rearc-processed_data/"

            populationMeanAndStdDf.write
                .format("json")
                .mode("overwrite")
                .save(baseS3Path + "population_mean_and_std.json")

            bestYearsDf.write
                .format("json")
                .mode("overwrite")
                .save(baseS3Path + "best_years.json")

            populationReportDf.write
                .format("json")
                .format("overwrite")
                .save(baseS3Path + "population_report.json")

        } catch {
            case ex: Throwable => throw ex
        } finally {
            spark.stop()
        }
    }
}
