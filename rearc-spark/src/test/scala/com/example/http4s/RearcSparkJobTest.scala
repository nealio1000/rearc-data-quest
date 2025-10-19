package com.neal.rearc_quest

import org.apache.spark.sql.{DataFrame, SparkSession}
import org.scalatest.funsuite.AnyFunSuiteLike
import org.scalatest.{BeforeAndAfterAll, Suite}


// Spark Test Fixture used for unit testing, provides a SparkSession to use
trait SparkTestFixture extends BeforeAndAfterAll { this: Suite =>

  @transient protected var spark: SparkSession = _

  protected def ss: SparkSession = spark

  override def beforeAll(): Unit = {
    super.beforeAll()
    spark = SparkSession.builder()
      .master("local[*]") // Use local mode for testing
      .appName("SparkTestSession")
      .config("spark.sql.shuffle.partitions", "1") // Optimize for local testing
      .getOrCreate()
  }

  override def afterAll(): Unit = {
    if (spark != null) {
      spark.stop()
      spark = null
    }
    super.afterAll()
  }
}


// TODO Add real tests for spark transformations
class RearcSparkJobTest extends AnyFunSuiteLike with BeforeAndAfterAll with SparkTestFixture {

  test("placeholder test") { ss: SparkSession =>
    import ss.implicits._

    // Prepare test data
    val testData = Seq(("Alice", 30), ("Bob", 25)).toDF("name", "age")

    // Define expected data
    val expectedData = Seq(("Alice", 30), ("Bob", 25)).toDF("name", "age")

    // Assertions
    // Compare the schema and data of the resulting DataFrame with the expected DataFrame
    assert(testData.schema === expectedData.schema)
    assert(testData.collect().sortBy(_.getString(0)) === expectedData.collect().sortBy(_.getString(0)))
  }
}