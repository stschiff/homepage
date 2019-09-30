--------------------------------------------------------------------------------
{-# LANGUAGE OverloadedStrings #-}
import           Data.Monoid (mappend)
import           Hakyll


--------------------------------------------------------------------------------
main :: IO ()
main = hakyll $ do
    match "images/*" $ do
        route   idRoute
        compile copyFileCompiler

    match "css/*" $ do
        route   idRoute
        compile compressCssCompiler

    match "pages/*" $ do
        route   $ gsubRoute "pages/" (const "") `composeRoutes` setExtension "html"
        compile $ do
            baseCtx <- getBaseCtx True True Nothing
            pandocCompiler
                >>= loadAndApplyTemplate "templates/base.html" baseCtx
                >>= relativizeUrls

    match "posts/*" $ do
        route $ setExtension "html"
        compile $ do
            baseCtx <- getBaseCtx False True Nothing
            pandocCompiler
                >>= loadAndApplyTemplate "templates/post.html" postCtx
                >>= loadAndApplyTemplate "templates/base.html" baseCtx
                >>= relativizeUrls

    match "publications/*" $ do
        compile pandocCompiler
        
    create ["blog.html"] $ do
        route idRoute
        compile $ do
            posts <- recentFirst =<< loadAll "posts/*"
            let blogCtx =
                    listField  "posts" postCtx (return posts) <>
                    defaultContext
            baseCtx <- getBaseCtx False True (Just "Blog")
            makeItem ""
                >>= loadAndApplyTemplate "templates/blog.html" blogCtx
                >>= loadAndApplyTemplate "templates/base.html" baseCtx
                >>= relativizeUrls

    create ["publications.html"] $ do
        route idRoute
        compile $ do
            pubs <- recentFirst =<< loadAll "publications/*"
            let pubCtx =
                    listField  "pubs"  postCtx (return pubs) <>
                    defaultContext
            baseCtx <- getBaseCtx True False (Just "Publications")
            makeItem ""
                >>= loadAndApplyTemplate "templates/publications.html" pubCtx
                >>= loadAndApplyTemplate "templates/base.html" baseCtx
                >>= relativizeUrls

    match "templates/*" $ compile templateBodyCompiler

postCtx :: Context String
postCtx =
    dateField "date" "%B %e, %Y" `mappend`
    defaultContext

getBaseCtx :: Bool -> Bool -> Maybe String -> Compiler (Context String)
getBaseCtx withPosts withPubs maybeTitle = do
    posts <- if withPosts
        then do
            recentFirst =<< loadAll "posts/*"
        else
            return mempty
    pubs <- if withPubs
        then do
            recentFirst =<< loadAll "publications/*"
        else
            return mempty
    let sidebarField = listField "sidebarItems" postCtx (return (posts <> pubs))
        titleField = case maybeTitle of
            Nothing -> mempty
            Just t -> constField "title" t
    return $ sidebarField <> titleField <> defaultContext

