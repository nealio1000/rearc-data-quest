val LogbackVersion = "1.5.19"
val SparkVersion = "3.5.1"
val ScalaLogging = "3.9.3"

val deps = Seq(
    "com.typesafe.scala-logging"    %% "scala-logging"              % ScalaLogging,
    "org.apache.spark"              %% "spark-sql"                  % SparkVersion,
    "ch.qos.logback"                %  "logback-classic"            % LogbackVersion            % Runtime,
)

lazy val root = (project in file("."))
    .settings(
        organization := "com.neal",
        name := "rearc-spark",
        version := "0.0.1-SNAPSHOT",
        scalaVersion := "2.12.20",
        libraryDependencies ++= deps
    )