module Return3 exposing (Return, addCommand, addReplies, addReply, andThen, cast, castNested, commandWithModel, from2, fromDebouncer, mapCmd, mapModel, mapReplies, repliesWithModel, replyWithModel, return, returnCommandWithModel, returnRepliesWithModel, returnReplyWithModel, three, wield, wieldNested)

import Maybe.Extra as Maybe



-- 🌳


type alias Return model msg reply =
    ( model, Cmd msg, List reply )



-- 🔱


andThen : (model -> Return model msg reply) -> Return model msg reply -> Return model msg reply
andThen update ( model, cmd, replies ) =
    let
        ( newModel, newCmd, newReplies ) =
            update model
    in
    ( newModel
    , Cmd.batch [ cmd, newCmd ]
    , replies ++ newReplies
    )


from2 : ( model, Cmd msg ) -> Return model msg reply
from2 ( model, cmd ) =
    ( model, cmd, [] )


return : model -> Return model msg reply
return model =
    ( model, Cmd.none, [] )


returnCommandWithModel : model -> Cmd msg -> Return model msg reply
returnCommandWithModel model cmd =
    ( model, cmd, [] )


returnRepliesWithModel : model -> List reply -> Return model msg reply
returnRepliesWithModel model replies =
    ( model, Cmd.none, replies )


returnReplyWithModel : model -> reply -> Return model msg reply
returnReplyWithModel model reply =
    ( model, Cmd.none, [ reply ] )


three : model -> Cmd msg -> List reply -> Return model msg reply
three model cmd replies =
    ( model, cmd, replies )



-- 🔱  ░░  ALIASES


commandWithModel =
    returnCommandWithModel


repliesWithModel =
    returnRepliesWithModel


replyWithModel =
    returnReplyWithModel



-- 🔱  ░░  MODIFICATIONS


addCommand : Cmd msg -> Return model msg reply -> Return model msg reply
addCommand cmd ( model, earlierCmd, replies ) =
    ( model
    , Cmd.batch [ earlierCmd, cmd ]
    , replies
    )


addReply : reply -> Return model msg reply -> Return model msg reply
addReply reply =
    addReplies [ reply ]


addReplies : List reply -> Return model msg reply -> Return model msg reply
addReplies replies ( model, cmd, earlierReplies ) =
    ( model
    , cmd
    , earlierReplies ++ replies
    )


mapCmd : (msg -> newMsg) -> Return model msg reply -> Return model newMsg reply
mapCmd fn ( model, cmd, replies ) =
    ( model, Cmd.map fn cmd, replies )


mapModel : (model -> newModel) -> Return model msg reply -> Return newModel msg reply
mapModel fn ( model, cmd, replies ) =
    ( fn model, cmd, replies )


mapReplies : (reply -> newReply) -> Return model msg reply -> Return model msg newReply
mapReplies fn ( model, cmd, replies ) =
    ( model, cmd, List.map fn replies )



-- 🔱  ░░  WIELDING
--
-- Return3 -> Return2


wield :
    (reply -> model -> ( model, Cmd msg ))
    -> Return model msg reply
    -> ( model, Cmd msg )
wield replyTransformer ( model, cmd, replies ) =
    List.foldl
        (\reply ( accModel, accCmd ) ->
            Tuple.mapSecond
                (\c -> Cmd.batch [ accCmd, c ])
                (replyTransformer reply accModel)
        )
        ( model
        , cmd
        )
        replies


wieldNested :
    (reply -> model -> ( model, Cmd msg ))
    ->
        { mapCmd : subMsg -> msg
        , mapModel : subModel -> model
        , update : subMsg -> subModel -> Return subModel subMsg reply
        }
    ->
        { model : subModel
        , msg : subMsg
        }
    -> ( model, Cmd msg )
wieldNested replyTransformer a b =
    let
        cmdTransformer =
            a.mapCmd

        modelTransformer =
            a.mapModel

        ( subModel, subCmd, replies ) =
            a.update b.msg b.model
    in
    wield
        replyTransformer
        ( modelTransformer subModel
        , Cmd.map cmdTransformer subCmd
        , replies
        )



-- 🔱  ░░  CASTING
--
-- Return3 -> Return3


cast :
    (reply -> model -> Return model msg otherReply)
    -> Return model msg reply
    -> Return model msg otherReply
cast replyTransformer ( model, cmd, replies ) =
    List.foldl
        (\reply ( accModel, accCmd, accReplies ) ->
            accModel
                |> replyTransformer reply
                |> (\( m, c, r ) -> ( m, Cmd.batch [ accCmd, c ], accReplies ++ r ))
        )
        ( model
        , cmd
        , []
        )
        replies


castNested :
    (reply -> model -> Return model msg otherReply)
    ->
        { mapCmd : subMsg -> msg
        , mapModel : subModel -> model
        , update : subMsg -> subModel -> Return subModel subMsg reply
        }
    ->
        { model : subModel
        , msg : subMsg
        }
    -> Return model msg otherReply
castNested replyTransformer a b =
    let
        cmdTransformer =
            a.mapCmd

        modelTransformer =
            a.mapModel

        ( subModel, subCmd, replies ) =
            a.update b.msg b.model
    in
    cast
        replyTransformer
        ( modelTransformer subModel
        , Cmd.map cmdTransformer subCmd
        , replies
        )



-- 🔱  ░░  DEBOUNCER


fromDebouncer : ( model, Cmd msg, Maybe reply ) -> Return model msg reply
fromDebouncer ( a, b, c ) =
    ( a, b, Maybe.unwrap [] List.singleton c )
