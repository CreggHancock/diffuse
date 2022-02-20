module UI.Sources.View exposing (view)

import Chunky exposing (..)
import Conditional exposing (ifThenElse)
import Dict.Ext as Dict
import Html exposing (Html, text)
import Html.Attributes exposing (href)
import Html.Lazy as Lazy
import List.Extra as List
import Material.Icons as Icons
import Material.Icons.Types exposing (Coloring(..))
import Sources exposing (..)
import UI.Kit
import UI.List
import UI.Navigation exposing (..)
import UI.Page as Page
import UI.Sources.Form as Form
import UI.Sources.Page as Sources exposing (..)
import UI.Sources.Types exposing (Msg(..))
import UI.Types as UI exposing (Model)



-- 🌳


type alias PartialModel =
    { processingContext : List ( String, Float )
    , processingError : Maybe { error : String, sourceId : String }
    , sources : List Source
    }



-- 🗺


view : Sources.Page -> Model -> Html UI.Msg
view page model =
    Html.map UI.SourcesMsg
        (case page of
            Index ->
                Lazy.lazy2
                    (\a b -> receptacle <| index a b)
                    (List.length model.tracks.untouched)
                    { processingContext = model.processingContext
                    , processingError = model.processingError
                    , sources = model.sources
                    }

            Edit _ ->
                lazyForm model <| Form.edit

            New ->
                lazyForm model <| Form.new { onboarding = False }

            NewOnboarding ->
                lazyForm model <| Form.new { onboarding = True }

            NewThroughRedirect _ _ ->
                lazyForm model <| Form.new { onboarding = False }

            Rename _ ->
                lazyForm model <| Form.rename
        )


lazyForm model formView =
    Lazy.lazy (formView >> receptacle) model.sourceForm


receptacle =
    UI.Kit.receptacle { scrolling = True }



-- INDEX


index : Int -> PartialModel -> List (Html Msg)
index amountOfTracks model =
    [ -----------------------------------------
      -- Navigation
      -----------------------------------------
      if List.isEmpty model.sources then
        UI.Navigation.local
            [ ( Icon Icons.add
              , Label "Add a new source" Shown
              , NavigateToPage (Page.Sources New)
              )
            ]

      else
        UI.Navigation.local
            [ ( Icon Icons.add
              , Label "Add a new source" Shown
              , NavigateToPage (Page.Sources New)
              )

            -- Process
            ----------
            , if List.isEmpty model.processingContext then
                ( Icon Icons.sync
                , Label "Process sources" Shown
                , PerformMsg Process
                )

              else
                ( Icon Icons.sync
                , Label "Stop processing ..." Shown
                , PerformMsg StopProcessing
                )
            ]

    -----------------------------------------
    -- Content
    -----------------------------------------
    , if List.isEmpty model.sources then
        chunk
            [ "relative" ]
            [ chunk
                [ "absolute", "left-0", "top-0" ]
                [ UI.Kit.canister [ UI.Kit.h1 "Sources" ] ]
            ]

      else
        UI.Kit.canister
            [ UI.Kit.h1 "Sources"

            -- Intro
            --------
            , intro amountOfTracks

            -- List
            -------
            , model.sources
                |> List.sortBy
                    lowercaseName
                |> List.map
                    (\source ->
                        { label = Html.text (Dict.fetch "name" "" source.data)
                        , actions = sourceActions model.processingContext model.processingError source
                        , msg = Nothing
                        , isSelected = False
                        }
                    )
                |> UI.List.view UI.List.Normal
            ]

    --
    , if List.isEmpty model.sources then
        UI.Kit.centeredContent
            [ slab
                Html.a
                [ href (Page.toString <| Page.Sources New) ]
                [ "block"
                , "opacity-30"
                , "text-inherit"
                ]
                [ Icons.music_note 64 Inherit ]
            , slab
                Html.a
                [ href (Page.toString <| Page.Sources New) ]
                [ "block"
                , "leading-normal"
                , "mt-2"
                , "opacity-40"
                , "text-center"
                , "text-inherit"
                ]
                [ text "A source is a place where music is stored,"
                , lineBreak
                , text "add one so you can play some music "
                , inline
                    [ "align-middle", "inline-block", "-mt-px" ]
                    [ Icons.add 14 Inherit ]
                ]
            ]

      else
        nothing
    ]


intro : Int -> Html Msg
intro amountOfTracks =
    [ text "A source is a place where your music is stored."
    , lineBreak
    , text "By connecting a source, the application will scan it and keep a list of all the music in it."
    , lineBreak
    , text "You currently have "
    , text (String.fromInt amountOfTracks)
    , text " "
    , text (ifThenElse (amountOfTracks == 1) "track" "tracks")
    , text " in your collection."
    ]
        |> raw
        |> UI.Kit.intro


sourceActions : List ( String, Float ) -> Maybe { error : String, sourceId : String } -> Source -> List (UI.List.Action Msg)
sourceActions processingContext processingError source =
    let
        processIndex =
            List.findIndex (Tuple.first >> (==) source.id) processingContext

        process =
            Maybe.andThen (\idx -> List.getAt idx processingContext) processIndex
    in
    List.append
        (case ( process, processingError ) of
            ( Just ( _, progress ), _ ) ->
                [ { icon =
                        \_ _ ->
                            if progress < 0.05 then
                                inline
                                    [ "inline-block", "opacity-70", "px-1" ]
                                    [ case processIndex of
                                        Just 0 ->
                                            Html.text "Listing"

                                        _ ->
                                            Html.text "Waiting"
                                    ]

                            else
                                progress
                                    |> (*) 100
                                    |> round
                                    |> String.fromInt
                                    |> (\s -> s ++ "%")
                                    |> Html.text
                                    |> List.singleton
                                    |> inline [ "inline-block", "opacity-70", "px-1" ]
                  , msg = Nothing
                  , title = ""
                  }
                , { icon = Icons.sync
                  , msg = Nothing
                  , title = "Currently processing"
                  }
                ]

            ( Nothing, Just { error, sourceId } ) ->
                if sourceId == source.id then
                    [ { icon = \size _ -> Icons.error_outline size (Color UI.Kit.colors.error)
                      , msg = Nothing
                      , title = error
                      }
                    ]

                else
                    []

            _ ->
                []
        )
        [ { icon =
                if source.enabled then
                    Icons.check

                else
                    Icons.block
          , msg =
                { sourceId = source.id }
                    |> ToggleActivation
                    |> always
                    |> Just
          , title =
                if source.enabled then
                    "Enabled (click to disable)"

                else
                    "Disabled (click to enable)"
          }

        --
        , { icon = Icons.more_vert
          , msg = Just (SourceContextMenu source)
          , title = "Menu"
          }
        ]



-- 🛠


lowercaseName : Source -> String
lowercaseName =
    .data >> Dict.fetch "name" "" >> String.toLower
