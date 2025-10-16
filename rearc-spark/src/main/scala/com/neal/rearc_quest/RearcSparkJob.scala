import org.apache.spark.sql._
import org.apache.spark.sql.functions._
import org.apache.spark.sql.types._
import com.typesafe.scalalogging.LazyLogging
import org.apache.spark.Partitioner

object RearcSparkJob extends LazyLogging {

    def main(args: Array[String]): Unit = {
        val spark = SparkSession.builder
        .master("local")
        .appName("Rearc Spark Job")
        .getOrCreate()

    import spark.implicits._

    spark.conf.set("spark.sql.caseSensitive", true)

    try {
        // read in bls file time series data

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
