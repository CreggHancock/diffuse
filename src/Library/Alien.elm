module Alien exposing (Event, Tag(..), broadcast, report, tagFromString, tagToString, trigger)

{-| 👽 Aliens.

This involves the incoming and outgoing data.
Including the communication between the different Elm apps/workers.

-}

import Json.Encode



-- 🌳


type alias Event =
    { tag : String, data : Json.Encode.Value, error : Maybe String }


type Tag
    = AuthAnonymous
    | AuthEnclosedData
    | AuthIpfs
    | AuthMethod
    | Report
    | SearchTracks
      -- from UI
    | ProcessSources
    | SaveEnclosedUserData
    | SaveFavourites
    | SaveSources
    | SaveTracks
    | SignIn
    | SignOut
      -- to UI
    | AddTracks
    | FinishedProcessingSources
    | HideLoadingScreen
    | LoadEnclosedUserData
    | LoadHypaethralUserData
    | RemoveTracksByPath
    | ReportProcessingError
    | UpdateSourceData



-- 🔱


broadcast : Tag -> Json.Encode.Value -> Event
broadcast tag data =
    { tag = tagToString tag
    , data = data
    , error = Nothing
    }


report : Tag -> String -> Event
report tag error =
    { tag = tagToString tag
    , data = Json.Encode.null
    , error = Just error
    }


trigger : Tag -> Event
trigger tag =
    { tag = tagToString tag
    , data = Json.Encode.null
    , error = Nothing
    }


tagToString : Tag -> String
tagToString tag =
    case tag of
        AuthAnonymous ->
            "AUTH_ANONYMOUS"

        AuthIpfs ->
            "AUTH_IPFS"

        AuthMethod ->
            "AUTH_METHOD"

        AuthEnclosedData ->
            "AUTH_ENCLOSED_DATA"

        Report ->
            "REPORT"

        SearchTracks ->
            "SEARCH_TRACKS"

        -----------------------------------------
        -- From UI
        -----------------------------------------
        ProcessSources ->
            "PROCESS_SOURCES"

        SaveEnclosedUserData ->
            "SAVE_ENCLOSED_USER_DATA"

        SaveFavourites ->
            "SAVE_FAVOURITES"

        SaveSources ->
            "SAVE_SOURCES"

        SaveTracks ->
            "SAVE_TRACKS"

        SignIn ->
            "SIGN_IN"

        SignOut ->
            "SIGN_OUT"

        -----------------------------------------
        -- To UI
        -----------------------------------------
        AddTracks ->
            "ADD_TRACKS"

        FinishedProcessingSources ->
            "FINISHED_PROCESSING_SOURCES"

        HideLoadingScreen ->
            "HIDE_LOADING_SCREEN"

        LoadEnclosedUserData ->
            "LOAD_ENCLOSED_USER_DATA"

        LoadHypaethralUserData ->
            "LOAD_HYPAETHRAL_USER_DATA"

        RemoveTracksByPath ->
            "REMOVE_TRACKS_BY_PATH"

        ReportProcessingError ->
            "REPORT_PROCESSING_ERROR"

        UpdateSourceData ->
            "UPDATE_SOURCE_DATA"


tagFromString : String -> Maybe Tag
tagFromString string =
    case string of
        "AUTH_ANONYMOUS" ->
            Just AuthAnonymous

        "AUTH_IPFS" ->
            Just AuthIpfs

        "AUTH_METHOD" ->
            Just AuthMethod

        "AUTH_ENCLOSED_DATA" ->
            Just AuthEnclosedData

        "REPORT" ->
            Just Report

        "SEARCH_TRACKS" ->
            Just SearchTracks

        -----------------------------------------
        -- From UI
        -----------------------------------------
        "PROCESS_SOURCES" ->
            Just ProcessSources

        "SAVE_ENCLOSED_USER_DATA" ->
            Just SaveEnclosedUserData

        "SAVE_FAVOURITES" ->
            Just SaveFavourites

        "SAVE_SOURCES" ->
            Just SaveSources

        "SAVE_TRACKS" ->
            Just SaveTracks

        "SIGN_IN" ->
            Just SignIn

        "SIGN_OUT" ->
            Just SignOut

        -----------------------------------------
        -- UI
        -----------------------------------------
        "ADD_TRACKS" ->
            Just AddTracks

        "FINISHED_PROCESSING_SOURCES" ->
            Just FinishedProcessingSources

        "HIDE_LOADING_SCREEN" ->
            Just HideLoadingScreen

        "LOAD_ENCLOSED_USER_DATA" ->
            Just LoadEnclosedUserData

        "LOAD_HYPAETHRAL_USER_DATA" ->
            Just LoadHypaethralUserData

        "REMOVE_TRACKS_BY_PATH" ->
            Just RemoveTracksByPath

        "REPORT_PROCESSING_ERROR" ->
            Just ReportProcessingError

        "UPDATE_SOURCE_DATA" ->
            Just UpdateSourceData

        _ ->
            Nothing
