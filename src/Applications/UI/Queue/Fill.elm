module UI.Queue.Fill exposing (State, cleanAutoGenerated, ordered, queueLength, shuffled)

{-| These functions will return a new list for the `future` property.
-}

import Array
import List.Extra as List
import Maybe.Ext as Maybe
import Maybe.Extra as Maybe
import Queue exposing (Item, makeItem)
import Random exposing (Generator, Seed)
import Time
import Tracks exposing (IdentifiedTrack)



-- ⛩


queueLength : Int
queueLength =
    30



-- 🌳


type alias State =
    { activeItem : Maybe Item
    , future : List Item
    , ignored : List Item
    , past : List Item
    }



-- 🔱  ░░  ORDERED


ordered : Time.Posix -> List IdentifiedTrack -> State -> List Item
ordered _ unfilteredTracks state =
    let
        tracks =
            state.ignored
                |> List.map itemTrackId
                |> Tuple.pair []
                |> purifier unfilteredTracks
                |> Tuple.first

        manualEntries =
            List.filter (.manualEntry >> (==) True) state.future

        remaining =
            max (queueLength - List.length manualEntries) 0

        focus =
            Maybe.preferFirst (List.last manualEntries) state.activeItem
    in
    case focus of
        Just item ->
            let
                maybeNowPlayingIndex =
                    List.findIndex
                        (Tracks.isNowPlaying item.identifiedTrack)
                        tracks
            in
            maybeNowPlayingIndex
                |> Maybe.map (\idx -> List.drop (idx + 1) tracks)
                |> Maybe.withDefault tracks
                |> List.take remaining
                |> (\a ->
                        let
                            actualRemaining =
                                remaining - List.length a

                            n =
                                Maybe.withDefault (List.length tracks) maybeNowPlayingIndex
                        in
                        a ++ List.take (min n actualRemaining) tracks
                   )
                |> List.map (makeItem False)
                |> List.append manualEntries

        Nothing ->
            tracks
                |> List.take remaining
                |> List.map (makeItem False)
                |> List.append manualEntries



-- 🔱  ░░  SHUFFLED


shuffled : Time.Posix -> List IdentifiedTrack -> State -> List Item
shuffled timestamp unfilteredTracks s =
    let
        state =
            if List.isEmpty s.future && not (List.isEmpty s.past) then
                -- We played every available track,
                -- disregard the past tracks.
                { s | past = [] }

            else
                s

        idsToIgnore =
            [ state.ignored
            , state.past
            , state.future
            , Maybe.unwrap [] List.singleton state.activeItem
            ]
                |> List.map (List.map itemTrackId)
                |> List.concat
                |> List.unique

        tracks =
            ( [], idsToIgnore )
                |> purifier unfilteredTracks
                |> Tuple.first
                |> Array.fromList

        amountOfTracks =
            Array.length tracks

        generator =
            Random.int 0 (amountOfTracks - 1)

        toAmount =
            max (queueLength - List.length state.future) 0

        howMany =
            min toAmount amountOfTracks
    in
    if howMany > 0 then
        timestamp
            |> Time.posixToMillis
            |> Random.initialSeed
            |> generateIndexes generator howMany []
            |> List.foldl
                (\idx acc ->
                    case Array.get idx tracks of
                        Just track ->
                            makeItem False track :: acc

                        Nothing ->
                            acc
                )
                []
            |> List.append state.future

    else
        state.future



-- 🔱


cleanAutoGenerated : Bool -> String -> List Item -> List Item
cleanAutoGenerated shuffle trackId future =
    case shuffle of
        True ->
            List.filterNot
                (\i -> i.manualEntry == False && itemTrackId i == trackId)
                future

        False ->
            future



-- ㊙️


{-| Generated random indexes.

    `squirrel` = accumulator, ie. collected indexes

-}
generateIndexes : Generator Int -> Int -> List Int -> Seed -> List Int
generateIndexes generator howMany squirrel seed =
    let
        ( index, newSeed ) =
            Random.step generator seed
    in
    if List.member index squirrel then
        generateIndexes generator howMany squirrel newSeed

    else if howMany - 1 > 0 then
        generateIndexes generator (howMany - 1) (index :: squirrel) newSeed

    else
        index :: squirrel



-- PURIFY


purifier :
    List IdentifiedTrack
    -> ( List IdentifiedTrack, List String )
    -> ( List IdentifiedTrack, List String )
purifier tracks ( acc, idsToIgnore ) =
    case idsToIgnore of
        [] ->
            -- Nothing more to ignore,
            -- stop here.
            ( acc ++ tracks, [] )

        _ ->
            case tracks of
                [] ->
                    -- No more tracks left,
                    -- end of the road.
                    ( acc, idsToIgnore )

                (( _, track ) as identifiedTrack) :: rest ->
                    case List.elemIndex track.id idsToIgnore of
                        Just ignoreIdx ->
                            -- It's a track to ignore,
                            -- remove it from the ignore list and carry on.
                            purifier
                                rest
                                ( acc, List.removeAt ignoreIdx idsToIgnore )

                        Nothing ->
                            -- It's not a track to ignore,
                            -- add it to the to-keep list and carry on.
                            purifier
                                rest
                                ( identifiedTrack :: acc, idsToIgnore )



-- COMMON


itemTrackId : Item -> String
itemTrackId =
    .identifiedTrack >> Tuple.second >> .id
