package com.neal.rearc_quest

import org.apache.spark.sql.{DataFrame, SparkSession}
import org.scalatest.funsuite.AnyFunSuite
import org.scalatest.BeforeAndAfterAll

class RearcSparkJobTest extends AnyFunSuite with BeforeAndAfterAll {

  // Declare SparkSession as a var to be initialized in beforeAll
  var spark: SparkSession = _

  override def beforeAll(): Unit = {
    // Initialize a local SparkSession for testing
    spark = SparkSession.builder
      .appName("Spark Unit Test")
      .master("local[*]") // Use local mode for testing
      .getOrCreate()
  }

  override def afterAll(): Unit = {
    // Stop the SparkSession after all tests are run
    if (spark != null) {
      spark.stop()
    }
  }

  // Define the function to be tested
  def addGreetingColumn(df: DataFrame): DataFrame = {
    import spark.implicits._
    df.withColumn("greeting", $"name" + " says hello!")
  }

  // add fixture for starting spark cluster

  // call a function that reads and sanitizes the input data

  // call a function that reads fails to sanitize the input data

  // call a function that aggregates the bls data and verifies the result

  // call a function that aggregates the bls data and verifies there is no result

  // call a function that verifies the write

  test("addGreetingColumn should add a greeting column correctly") {
    import spark.implicits._

    // 1. Prepare test data
    val testData = Seq(("Alice", 30), ("Bob", 25)).toDF("name", "age")

    // 2. Apply the transformation
    val resultDF = addGreetingColumn(testData)

    // 3. Define expected data
    val expectedData = Seq(("Alice", 30, "Alice says hello!"), ("Bob", 25, "Bob says hello!")).toDF("name", "age", "greeting")

    // 4. Assertions
    // Compare the schema and data of the resulting DataFrame with the expected DataFrame
    assert(resultDF.schema === expectedData.schema)
    assert(resultDF.collect().sortBy(_.getString(0)) === expectedData.collect().sortBy(_.getString(0)))
  }

  test("addGreetingColumn should handle empty DataFrame") {
    import spark.implicits._

    val emptyDF = spark.emptyDataFrame.withColumn("name", org.apache.spark.sql.types.StringType).withColumn("age", org.apache.spark.sql.types.IntegerType)

    val resultDF = addGreetingColumn(emptyDF)

    val expectedEmptyDF = spark.emptyDataFrame.withColumn("name", org.apache.spark.sql.types.StringType).withColumn("age", org.apache.spark.sql.types.IntegerType).withColumn("greeting", org.apache.spark.sql.types.StringType)

    assert(resultDF.schema === expectedEmptyDF.schema)
    assert(resultDF.collect().isEmpty)
  }
}