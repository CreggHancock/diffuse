module UI.Backdrop exposing (Model, Msg(..), backgroundPositioning, default, initialModel, options, update, view)

import Chunky exposing (..)
import Color exposing (Color)
import Css exposing (int, num, pct, px)
import Css.Global
import Html.Styled as Html exposing (Html, div)
import Html.Styled.Attributes exposing (class, css, src, style)
import Html.Styled.Events exposing (on)
import Html.Styled.Lazy as Lazy
import Json.Decode
import Return3 exposing (..)
import Tachyons.Classes as T
import UI.Animations
import UI.Ports as Ports
import UI.Reply as Reply exposing (Reply)



-- ⛩


default : String
default =
    "7.jpg"


options : List ( String, String )
options =
    [ ( "1.jpg", "Option 1" )
    , ( "2.jpg", "Option 2" )
    , ( "3.jpg", "Option 3" )
    , ( "4.jpg", "Option 4" )
    , ( "5.jpg", "Option 5" )
    , ( "6.jpg", "Option 6" )
    , ( "7.jpg", "Option 7 (default)" )
    , ( "8.jpg", "Option 8" )
    , ( "9.jpg", "Option 9" )
    , ( "10.jpg", "Option 10" )
    , ( "11.jpg", "Option 11" )
    , ( "12.jpg", "Option 12" )
    , ( "13.jpg", "Option 13" )
    , ( "14.jpg", "Option 14" )
    , ( "15.jpg", "Option 15" )
    , ( "16.jpg", "Option 16" )
    , ( "17.jpg", "Option 17" )
    , ( "18.jpg", "Option 18" )
    , ( "19.jpg", "Option 19" )
    , ( "20.jpg", "Option 20" )
    , ( "21.jpg", "Option 21" )
    ]



-- 🌳


type alias Model =
    { bgColor : Maybe Color
    , chosen : Maybe String
    , fadeIn : Bool
    , loaded : List String
    }


initialModel : Model
initialModel =
    { bgColor = Nothing
    , chosen = Nothing
    , fadeIn = True
    , loaded = []
    }



-- 📣


type Msg
    = BackgroundColor { r : Int, g : Int, b : Int }
    | Choose String
    | Default
    | Load String


update : Msg -> Model -> Return Model Msg Reply
update msg model =
    case msg of
        BackgroundColor { r, g, b } ->
            return { model | bgColor = Just (Color.rgb255 r g b) }

        Choose backdrop ->
            return { model | chosen = Just backdrop } |> addReply Reply.SaveSettings

        Default ->
            return { model | chosen = Just default }

        Load backdrop ->
            returnCommandWithModel
                { model | loaded = model.loaded ++ [ backdrop ] }
                (Ports.pickAverageBackgroundColor backdrop)



-- 🗺


view : Model -> Html Msg
view model =
    chunk
        [ T.absolute__fill
        , T.fixed
        , T.z_0
        ]
        [ Lazy.lazy chosen model.chosen
        , Lazy.lazy2 loaded model.loaded model.fadeIn

        -- Shadow
        ---------
        , brick
            [ style "background" "linear-gradient(#0000, rgba(0, 0, 0, 0.175))" ]
            [ T.absolute
            , T.bottom_0
            , T.h5
            , T.left_0
            , T.right_0
            , T.z_1
            ]
            []
        ]


backgroundPositioning : String -> Html.Attribute msg
backgroundPositioning filename =
    case filename of
        "2.jpg" ->
            style "background-position" "center 68%"

        "3.jpg" ->
            style "background-position" "center 30%"

        "4.jpg" ->
            style "background-position" "center 96.125%"

        "6.jpg" ->
            style "background-position" "center 40%"

        "11.jpg" ->
            style "background-position" "center 67.25%"

        "17.jpg" ->
            style "background-position" "center 87.5%"

        "19.jpg" ->
            style "background-position" "center 13%"

        "20.jpg" ->
            style "background-position" "center 39.75%"

        _ ->
            style "background-position" "center bottom"



-----------------------------------------
-- ㊙️
-----------------------------------------


chosen : Maybe String -> Html Msg
chosen maybeChosen =
    case maybeChosen of
        Just c ->
            let
                loadingDecoder =
                    c
                        |> Load
                        |> Json.Decode.succeed
            in
            slab
                Html.img
                [ css chosenStyles
                , on "load" loadingDecoder
                , src ("images/Background/" ++ c)
                ]
                [ T.fixed
                , T.overflow_hidden
                ]
                []

        Nothing ->
            nothing


loaded : List String -> Bool -> Html Msg
loaded list fadeIn =
    let
        amount =
            List.length list

        indexedMapFn idx item =
            div (imageStyles fadeIn (idx + 1 < amount) item) []
    in
    list
        |> List.indexedMap indexedMapFn
        |> div [ css imageContainerStyles ]



-- 🖼


chosenStyles : List Css.Style
chosenStyles =
    [ Css.height (px 1)
    , Css.left (pct 100)
    , Css.opacity (num 0.00001)
    , Css.top (pct 100)
    , Css.transform (Css.translate2 (px -1) (px -1))
    , Css.width (px 1)
    , Css.zIndex (int -10000)
    ]


imageContainerStyles : List Css.Style
imageContainerStyles =
    [ Css.Global.descendants
        [ Css.Global.selector
            ".bg-image--with-fadein"
            imageAnimation
        ]
    ]


imageAnimation : List Css.Style
imageAnimation =
    [ Css.animationName UI.Animations.fadeIn
    , Css.animationDuration (Css.ms 2000)
    , Css.animationDelay (Css.ms 50)
    , Css.property "animation-fill-mode" "forwards"
    ]


imageStyles : Bool -> Bool -> String -> List (Html.Attribute msg)
imageStyles fadeIn isPrevious loadedBackdrop =
    [ -- Animation
      ------------
      if not isPrevious && fadeIn then
        class "bg-image--with-fadein"

      else
        class ""

    -- Background
    -------------
    , backgroundPositioning loadedBackdrop

    -- Opacity
    ----------
    , if isPrevious || not fadeIn then
        style "opacity" "1"

      else
        style "opacity" "0"

    --
    , style "background-image" ("url(images/Background/" ++ loadedBackdrop ++ ")")
    , style "background-size" "cover"
    , style "bottom" "-1px"
    , style "left" "-1px"
    , style "position" "fixed"
    , style "right" "-1px"
    , style "top" "-1px"
    , style "z-index" "-9"
    ]
