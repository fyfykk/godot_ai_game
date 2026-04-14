@echo off
setlocal
set ROOT=%~dp0
if "%ROOT:~-1%"=="\" set ROOT=%ROOT:~0,-1%

set PROJECT_NAME=%~1
if "%PROJECT_NAME%"=="" set PROJECT_NAME=ai-game

where npm >nul 2>&1
if errorlevel 1 (
  echo npm not found. Install Node.js 18+ first.
  exit /b 1
)
where node >nul 2>&1
if errorlevel 1 (
  echo node not found. Install Node.js 18+ first.
  exit /b 1
)

for /f "usebackq delims=" %%i in (`node -p "process.versions.node.split('.')[0]"`) do set NODE_MAJOR=%%i
set WRANGLER_NPX=wrangler
if %NODE_MAJOR% LSS 20 (
  set WRANGLER_NPX=wrangler@3.114.12
  echo Detected Node.js %NODE_MAJOR%. Using %WRANGLER_NPX% for compatibility.
) else (
  echo Detected Node.js %NODE_MAJOR%. Using latest wrangler.
)

set USE_TOKEN_MODE=1
if "%CLOUDFLARE_API_TOKEN%"=="" set USE_TOKEN_MODE=0
if "%CLOUDFLARE_ACCOUNT_ID%"=="" set USE_TOKEN_MODE=0

if "%USE_TOKEN_MODE%"=="1" (
  echo Using token mode deployment.
) else (
  echo No CLOUDFLARE_API_TOKEN/CLOUDFLARE_ACCOUNT_ID found.
  echo Switching to browser-login mode.
  echo Checking Wrangler auth status...
  call npx --yes %WRANGLER_NPX% whoami >nul 2>&1
  if errorlevel 1 (
    echo Wrangler not logged in.
    echo If browser does not auto-open, use the auth URL printed below.
    call npx --yes %WRANGLER_NPX% login --browser false
    if errorlevel 1 (
      echo Wrangler login failed.
      exit /b 1
    )
  ) else (
    echo Wrangler already logged in.
  )
)

call "%ROOT%\build_web.bat"
if errorlevel 1 exit /b 1

if not exist "%ROOT%\build\web\index.html" (
  echo Missing build\web\index.html after build.
  exit /b 1
)

set CF_PAGES_PROJECT=%PROJECT_NAME%
echo Deploying build\web to Cloudflare Pages project: %CF_PAGES_PROJECT%
set DEPLOY_LOG=%ROOT%\build\pages_deploy.log

pushd "%ROOT%"
call npx --yes %WRANGLER_NPX% pages deploy build/web --project-name %CF_PAGES_PROJECT% > "%DEPLOY_LOG%" 2>&1
type "%DEPLOY_LOG%"
findstr /i /c:"does not exist" "%DEPLOY_LOG%" >nul 2>&1
if not errorlevel 1 (
  echo Cloudflare Pages project "%CF_PAGES_PROJECT%" not found. Creating it...
  call npx --yes %WRANGLER_NPX% pages project create %CF_PAGES_PROJECT% --production-branch main
  if errorlevel 1 (
    echo Project creation failed.
    popd
    exit /b 1
  )
  call npx --yes %WRANGLER_NPX% pages deploy build/web --project-name %CF_PAGES_PROJECT% > "%DEPLOY_LOG%" 2>&1
  type "%DEPLOY_LOG%"
)
set DEPLOY_EXIT=%errorlevel%
popd

if not "%DEPLOY_EXIT%"=="0" (
  echo Deploy failed.
  exit /b %DEPLOY_EXIT%
)

echo Deploy success.
echo Project: %CF_PAGES_PROJECT%
echo Dashboard: https://dash.cloudflare.com/
endlocal
