{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecursiveDo       #-}
module Lib
  ( reflex
  ) where
import Reflex
import Reflex.Dom
import Data.Map (Map)
import qualified Data.Map as Map
import Data.Text (pack, unpack, Text)
import Text.Read (readMaybe)
import Control.Applicative ((<*>), (<$>))
import Servant.Client
import Servant.API
import Common
import Network.HTTP.Client (newManager, defaultManagerSettings)

reflex :: IO()
reflex = do
  manager' <- newManager defaultManagerSettings
  res <- runClientM getUsers (ClientEnv manager' (BaseUrl Http "localhost" 6868 ""))

  mainWidget $
    el "div" $ do
    nx <- numberInput
    d <- dropdown Times (constDyn ops) def
    ny <- numberInput
    let values = zipDynWith (,) nx ny
        result = zipDynWith (\o (x,y) -> runOp o <$> x <*> y) (_dropdown_value d) values
        resultText = fmap (pack . show) result
    text " = "
    dynText resultText
    text $ pack $ show res

numberInput :: (MonadWidget t m) => m (Dynamic t (Maybe Double))
numberInput = do
  let errorState = "style" =: "border-color: red"
      validState = "style" =: "border-color: green"
  rec n <- textInput $ def & textInputConfig_inputType .~ "number"
                           & textInputConfig_initialValue .~ "0"
                           & textInputConfig_attributes .~ attrs
      let result = fmap (readMaybe . unpack) $ _textInput_value n
          attrs  = fmap (maybe errorState (const validState)) result
  return result

data Op = Plus | Minus | Times | Divide deriving (Eq, Ord)

ops :: Map Op Text
ops = Map.fromList [(Plus, "+"), (Minus, "-"), (Times, "*"), (Divide, "/")]

runOp :: Fractional a => Op -> a -> a -> a
runOp s = case s of
            Plus -> (+)
            Minus -> (-)
            Times -> (*)
            Divide -> (/)

getUsers :: ClientM [User]
postMessage :: Message -> ClientM [Message]
(getUsers :<|> postMessage) = client serviceAPI
