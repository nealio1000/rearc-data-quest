package com.neal.rearc_quest

import org.apache.spark.sql.{DataFrame, SparkSession}
import org.scalatest.funsuite.AnyFunSuiteLike
import org.scalatest.{BeforeAndAfterAll, Suite}



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


// TODO Add Tests
class RearcSparkJobTest extends AnyFunSuiteLike with BeforeAndAfterAll with SparkTestFixture {

  test("placeholder test") { ss: SparkSession =>
    import ss.implicits._

    // 1. Prepare test data
    val testData = Seq(("Alice", 30), ("Bob", 25)).toDF("name", "age")


    // 3. Define expected data
    val expectedData = Seq(("Alice", 30), ("Bob", 25)).toDF("name", "age")

    // 4. Assertions
    // Compare the schema and data of the resulting DataFrame with the expected DataFrame
    assert(testData.schema === expectedData.schema)
    assert(testData.collect().sortBy(_.getString(0)) === expectedData.collect().sortBy(_.getString(0)))
  }
}