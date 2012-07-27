@ECHO OFF
@REM *************************************************************************
@REM 
@REM This script is used to 
@REM  - generate weblogic maven plugin and weblogic full client
@REM  - install them to the local maven repository  
@REM Notes:
@REM  1. Tested with Weblogic 11g only (10.3.4 - 10.3.6)
@REM  2. M2_HOME and JAVA_HOME must be set
@REM *************************************************************************
GOTO :ENDFUNCTIONS

:usage
	echo JAVA_HOME and M2_HOME environment varuables must be set
	echo You also need to specify Oracle Middleware Home in the command line
	echo Usage: %1 "Path to Oracle Middleware Home"
	echo for example:
	echo %1 c:\oracle\Middleware
GOTO :EOF

:ENDFUNCTIONS
if "%1"=="" (
		CALL :usage %0
		GOTO :EOF	
) else (
	set MW_HOME=%1
	shift
)

IF NOT EXIST %MW_HOME%\registry.xml (
  echo Error: incorect Oracle Middleware Home: %MW_HOME%
  GOTO :EOF
)

if "%M2_HOME%"=="" (
	CALL :usage %0
	GOTO :EOF
)
if "%JAVA_HOME%"=="" (
	CALL :usage %0
	GOTO :EOF
)

set WL_HOME=%MW_HOME%\wlserver_10.3
set WL_LIBS_HOME=%WL_HOME%\server\lib

echo Extracting Weblogic Version
%JAVA_HOME%\bin\java -cp %WL_LIBS_HOME%\weblogic.jar weblogic.version |find "WebLogic Server" > wls.ver
for /f "tokens=1,2,3,4 delims=/ " %%a  in (wls.ver) do set dummy1=%%a&set dummy2=%%b&set WL_VERSION=%%c
echo Weblogic Version: %WL_VERSION%
del wls.ver

FOR %%f IN (wlfullclient, weblogic-maven-plugin) DO CALL :JAR_GEN %%f
GOTO :JAR_GEN_DONE
 :JAR_GEN
 cd %WL_LIBS_HOME%
 IF NOT EXIST %WL_LIBS_HOME%\%1.jar (
   %JAVA_HOME%\bin\java -jar %WL_LIBS_HOME%\wljarbuilder.jar -profile %1
 ) ELSE (
  echo %1.jar has been already generated
 )
 GOTO :EOF
:JAR_GEN_DONE

echo Installing Weblogic Maven Plugin
%JAVA_HOME%\bin\jar xvf weblogic-maven-plugin.jar  META-INF/maven/com.oracle.weblogic/weblogic-maven-plugin/pom.xml
copy %WL_LIBS_HOME%\META-INF\maven\com.oracle.weblogic\weblogic-maven-plugin\pom.xml %WL_LIBS_HOME%
cd %WL_LIBS_HOME%
start %M2_HOME%\bin\mvn install:install-file  -Dfile=%WL_LIBS_HOME%\weblogic-maven-plugin.jar -DpomFile=pom.xml

echo Installing Weblogic Full Client
start %M2_HOME%\bin\mvn install:install-file  -Dfile=%WL_LIBS_HOME%\wlfullclient.jar -DgroupId=com.oracle.weblogic -Dversion=%WL_VERSION% -DartifactId=wlfullclient -Dpackaging=jar -DgeneratePom=true -DcreateChecksum=true
