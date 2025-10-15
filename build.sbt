name := "rearc Data Quest"
version := "1.0"
scalaVersion := "2.12.20"
organization := "com.neal"

val Http4sVersion = "0.23.32"
val CirceVersion = "0.14.15"
val MunitVersion = "1.2.0"
val LogbackVersion = "1.5.19"
val MunitCatsEffectVersion = "2.1.0"

val deps = Seq(
    "com.typesafe.scala-logging" %% "scala-logging" % "3.9.3",
    "ch.qos.logback" % "logback-classic" % "1.2.10",
    "org.apache.spark" %% "spark-sql" % "3.5.1",
    "org.http4s"      %% "http4s-ember-server" % Http4sVersion,
    "org.http4s"      %% "http4s-ember-client" % Http4sVersion,
    "org.http4s"      %% "http4s-circe"        % Http4sVersion,
    "org.http4s"      %% "http4s-dsl"          % Http4sVersion,
    "io.circe"        %% "circe-generic"       % CirceVersion,
    "org.scalameta"   %% "munit"               % MunitVersion           % Test,
    "org.typelevel"   %% "munit-cats-effect"   % MunitCatsEffectVersion % Test,
    "ch.qos.logback"  %  "logback-classic"     % LogbackVersion         % Runtime,
)

libraryDependencies ++= deps

lazy val root = (project in file("."))
    .settings(
        organization := "com.neal",
        name := "rearc_quest",
        version := "0.0.1-SNAPSHOT",
        scalaVersion := "2.12.20",
        libraryDependencies ++= deps,
        addCompilerPlugin("org.typelevel" %% "kind-projector"     % "0.13.3" cross CrossVersion.full),
        addCompilerPlugin("com.olegpy"    %% "better-monadic-for" % "0.3.1"),
        assembly / assemblyMergeStrategy := {
            case "module-info.class" => MergeStrategy.discard
            case x => (assembly / assemblyMergeStrategy).value.apply(x)
        }
    )