port module Ports exposing (..)

import Json.Encode exposing (Value)


port parseText : String -> Cmd msg


port progress : (Value -> msg) -> Sub msg


port receiveText : (Value -> msg) -> Sub msg
