val LogbackVersion = "1.5.19"
val SparkVersion = "3.5.1"
val ScalaLogging = "3.9.3"
val ScalaTest = "3.2.19"
val HadoopAWS = "3.3.4"

val deps = Seq(
    "com.typesafe.scala-logging"    %% "scala-logging"              % ScalaLogging,
    "org.apache.spark"              %% "spark-core"                 % SparkVersion              % "provided",   // for local testing remove "provided"  
    "org.apache.spark"              %% "spark-sql"                  % SparkVersion              % "provided",   // for local testing remove "provided"  
    "org.apache.hadoop"             % "hadoop-aws"                  % HadoopAWS,
    "org.scalatest"                 %% "scalatest"                  % ScalaTest                 % Test
)

lazy val root = (project in file("."))
    .settings(
        organization := "com.neal",
        name := "rearc-spark",
        version := "0.0.1-SNAPSHOT",
        scalaVersion := "2.12.20",
        fork := true,
        libraryDependencies ++= deps,
        assembly / mainClass := Some("com.neal.rearc_quest.RearcSparkJob"),
        assembly / assemblyMergeStrategy := {
            case PathList("META-INF", "services", _*) => MergeStrategy.concat
            case PathList("META-INF", xs @ _*) => MergeStrategy.discard
            case x => MergeStrategy.first
        }
    )