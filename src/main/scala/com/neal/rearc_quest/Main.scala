package com.neal.rearc_quest

import cats.effect.{IO, IOApp}

object Main extends IOApp.Simple {
  val run = Http4sServer.run[IO]
}
