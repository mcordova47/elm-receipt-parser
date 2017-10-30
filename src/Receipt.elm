module Receipt exposing (Product, parseProduct)

import Regex


type alias Product =
    { name : String
    , price : Float
    }


parseProduct : String -> Maybe Product
parseProduct line =
    line
        |> Regex.find
            (Regex.AtMost 1)
            (Regex.regex "(.+)([0-9]+\\.[0-9]{2}).*F")
        |> List.map .submatches
        |> List.head
        |> Maybe.andThen getProduct


getProduct : List (Maybe String) -> Maybe Product
getProduct matches =
    case matches of
        [ Just name, Just price ] ->
            String.toFloat price
                |> Result.toMaybe
                |> Maybe.map (Product name)

        _ ->
            Nothing
