package com.neal.rearc_quest

import org.apache.spark.sql._
import org.apache.spark.sql.functions._
import org.apache.spark.sql.types._
import com.typesafe.scalalogging.LazyLogging
import org.apache.spark.Partitioner

object RearcSparkJob extends LazyLogging {

    def main(args: Array[String]): Unit = {
        val spark = SparkSession.builder
            .appName("Rearc Spark Job")
            .config("spark.hadoop.fs.s3a.impl", "org.apache.hadoop.fs.s3a.S3AFileSystem")
            .config("spark.hadoop.mapreduce.fileoutputcommitter.algorithm.version", "2")
            .config("spark.sql.caseSensitive", true)
            .getOrCreate()

        import spark.implicits._

        val rawDataBucket = "rearc-quest-raw-data-bucket"

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
                .csv(f"s3a://$rawDataBucket/bls-data/pr.data.0.Current")

            // read in population data
            val populationDf = spark.read
                .option("multiline", "true")
                .json(f"s3a://$rawDataBucket/population/population.json")
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
                
            val processedDataBucket = "s3a://rearc-quest-processed-data-bucket/"

            populationMeanAndStdDf.coalesce(1).write
                .format("json")
                .mode("overwrite")
                .json(processedDataBucket + "population_mean_and_std")

            bestYearsDf.coalesce(1).write
                .format("json")
                .mode("overwrite")
                .json(processedDataBucket + "best_years")

            populationReportDf.coalesce(1).write
                .format("json")
                .mode("overwrite")
                .json(processedDataBucket + "population_report")

        } catch {
            case ex: Throwable => throw ex
        } finally {
            spark.stop()
        }
    }
}
