@echo off
setlocal
set ROOT=%~dp0
if "%ROOT:~-1%"=="\" set ROOT=%ROOT:~0,-1%

set SITE_NAME=%~1
if "%SITE_NAME%"=="" set SITE_NAME=ai-game-web
set NETLIFY_NPX=netlify-cli@17.38.1
set DEPLOY_LOG=%ROOT%\build\netlify_deploy.log

where npm >nul 2>&1
if errorlevel 1 (
  echo npm not found. Install Node.js 18+ first.
  exit /b 1
)

echo Checking Netlify auth status...
call npx --yes %NETLIFY_NPX% status >nul 2>&1
if errorlevel 1 (
  echo Netlify not logged in. Browser login required once.
  call npx --yes %NETLIFY_NPX% login
  if errorlevel 1 (
    echo Netlify login failed.
    exit /b 1
  )
)

call "%ROOT%\build_web.bat"
if errorlevel 1 exit /b 1

if not exist "%ROOT%\build\web\index.html" (
  echo Missing build\web\index.html after build.
  exit /b 1
)

echo Deploying build\web to Netlify site: %SITE_NAME%
pushd "%ROOT%"
call npx --yes %NETLIFY_NPX% deploy --prod --dir build/web --site %SITE_NAME% > "%DEPLOY_LOG%" 2>&1
type "%DEPLOY_LOG%"

findstr /i /c:"Unauthorized" "%DEPLOY_LOG%" >nul 2>&1
if not errorlevel 1 (
  echo Netlify auth expired or missing. Running login...
  call npx --yes %NETLIFY_NPX% login
  if errorlevel 1 (
    echo Netlify login failed.
    popd
    exit /b 1
  )
  call npx --yes %NETLIFY_NPX% deploy --prod --dir build/web --site %SITE_NAME% > "%DEPLOY_LOG%" 2>&1
  type "%DEPLOY_LOG%"
)

findstr /i /c:"Site not found" "%DEPLOY_LOG%" >nul 2>&1
if not errorlevel 1 (
  echo Site "%SITE_NAME%" not found. Creating it...
  call npx --yes %NETLIFY_NPX% sites:create --name %SITE_NAME%
  if errorlevel 1 (
    echo Site creation failed.
    popd
    exit /b 1
  )
  call npx --yes %NETLIFY_NPX% deploy --prod --dir build/web --site %SITE_NAME% > "%DEPLOY_LOG%" 2>&1
  type "%DEPLOY_LOG%"
)

set DEPLOY_EXIT=%errorlevel%
popd

if not "%DEPLOY_EXIT%"=="0" (
  echo Deploy failed.
  exit /b %DEPLOY_EXIT%
)

echo Deploy success.
echo Netlify URL usually looks like: https://%SITE_NAME%.netlify.app
endlocal
