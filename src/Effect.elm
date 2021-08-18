module Effect exposing
    ( BackendOnly
    , Effect
    , FrontendOnly
    , PortToJs
    , batch
    , map
    , none
    , sendToJs
    )

import Effect.Internal exposing (Effect(..), NavigationKey, Subscription(..))
import Effect.Task
import Json.Encode


type alias FrontendOnly =
    Effect.Internal.FrontendOnly


type alias BackendOnly =
    Effect.Internal.BackendOnly


type alias Effect restriction toMsg msg =
    Effect.Internal.Effect restriction toMsg msg


batch : List (Effect restriction toMsg msg) -> Effect restriction toMsg msg
batch =
    Batch


none : Effect restriction toMsg msg
none =
    None


sendToJs : String -> (Json.Encode.Value -> Cmd msg) -> Json.Encode.Value -> Effect FrontendOnly toMsg msg
sendToJs =
    Port


type alias PortToJs =
    { portName : String, value : Json.Encode.Value }


map :
    (toBackendA -> toBackendB)
    -> (frontendMsgA -> frontendMsgB)
    -> Effect restriction toBackendA frontendMsgA
    -> Effect restriction toBackendB frontendMsgB
map mapToMsg mapMsg frontendEffect =
    case frontendEffect of
        Batch frontendEffects ->
            List.map (map mapToMsg mapMsg) frontendEffects |> Batch

        None ->
            None

        SendToBackend toMsg ->
            mapToMsg toMsg |> SendToBackend

        NavigationPushUrl navigationKey url ->
            NavigationPushUrl navigationKey url

        NavigationReplaceUrl navigationKey url ->
            NavigationReplaceUrl navigationKey url

        NavigationLoad url ->
            NavigationLoad url

        NavigationBack navigationKey int ->
            NavigationBack navigationKey int

        NavigationForward navigationKey int ->
            NavigationForward navigationKey int

        NavigationReload ->
            NavigationReload

        NavigationReloadAndSkipCache ->
            NavigationReloadAndSkipCache

        Task simulatedTask ->
            Effect.Task.map mapMsg simulatedTask
                |> Effect.Task.mapError mapMsg
                |> Task

        Port portName function value ->
            Port portName (function >> Cmd.map mapMsg) value

        SendToFrontend clientId toMsg ->
            SendToFrontend clientId (mapToMsg toMsg)

        FileDownloadUrl record ->
            FileDownloadUrl record

        FileDownloadString record ->
            FileDownloadString record

        FileDownloadBytes record ->
            FileDownloadBytes record

        FileSelectFile strings function ->
            FileSelectFile strings (function >> mapMsg)

        FileSelectFiles strings function ->
            FileSelectFiles strings (\file restOfFiles -> function file restOfFiles |> mapMsg)

        Broadcast toMsg ->
            Broadcast (mapToMsg toMsg)
