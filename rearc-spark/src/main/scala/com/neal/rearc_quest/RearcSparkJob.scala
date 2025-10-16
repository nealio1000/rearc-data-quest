import org.apache.spark.sql._
import org.apache.spark.sql.functions._
import org.apache.spark.sql.types._
import com.typesafe.scalalogging.LazyLogging
import org.apache.spark.Partitioner

object SimpleApp extends LazyLogging {

    def main(args: Array[String]): Unit = {
        val spark = SparkSession.builder
        .master("local")
        .appName("Simple Application")
        .getOrCreate()

    import spark.implicits._

    spark.conf.set("spark.sql.caseSensitive", true)

    try {
        // read in bls file time series data


        } catch {
            case ex: Throwable => throw ex
        } finally {
            spark.stop()
        }
    }
}
