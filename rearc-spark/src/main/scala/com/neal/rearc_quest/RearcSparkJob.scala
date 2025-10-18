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
            val blsDf = spark.read
                .option("header", "true")
                .option("delimiter", "\t")
                .csv("s3a://rearc-quest-data-bucket/bls-data/pr.data.0.Current")

            // read in population data
            val populationDf = spark.read
                .option("multiline", "true")
                .json("s3a://rearc-quest-data-bucket/population/population.json")
                .select(col("data"))

            val exploded = populationDf
                .withColumn("exploded_value", explode(col("data")))
                .select(
                    col("exploded_value.Year").cast(IntegerType).as("year"),
                    col("exploded_value.Population").cast(LongType).as("population")
                )

            // broadcast data

            // aggregate time series data

            // join with broadcasted population data

            // write out result to s3

        } catch {
            case ex: Throwable => throw ex
        } finally {
            spark.stop()
        }
    }
}
