module BrowserX.Network (fetchURL,checkProtocol,downloadfile) where 

import Network.Browser
import Network.HTTP
import Network.URI
import Control.Monad.IO.Class (liftIO)
import qualified Data.ByteString as S
import Data.Conduit
import Data.Conduit.Binary as CB
import Network.HTTP.Conduit
import Data.List.Split

fetchURL :: String -> IO String
fetchURL url = do
    (_,rsp) <- browse $ do
        setAllowRedirects True
        request $ getRequest url
    return(rspBody rsp)

checkProtocol :: String -> String
checkProtocol url = 
    case (parseURI url) of
        Nothing     -> "http://" ++ url
        Just uri    ->
            if (scheme == "http:") then url 
            else
                error (scheme ++ "Protocol not supported")
            where scheme = uriScheme uri
            
downloadfile url = withManager $ \manager -> do
    req <- parseUrl url
    res <- http req manager
    responseBody res $$+- printProgress =$ CB.sinkFile (fileName url)

printProgress :: Conduit S.ByteString (ResourceT IO) S.ByteString
printProgress =
    loop 0
  where
    loop len = await >>= maybe (return ()) (\bs -> do
        let len' = len + S.length bs
        liftIO $ putStrLn $ "Bytes consumed: " ++ show len'
        yield bs
        loop len')
        
fileName :: String -> String
fileName path = last (splitOn "/" path)
