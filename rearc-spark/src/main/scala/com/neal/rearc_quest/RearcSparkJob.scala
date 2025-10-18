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
            val df = spark.read
                .option("header", "true")
                .csv("s3a://rearc-quest-data-bucket/bls-data/pr.data.0.Current")

            df.show()


            // do any necessary sanitation on bls file

            // read in population data

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
