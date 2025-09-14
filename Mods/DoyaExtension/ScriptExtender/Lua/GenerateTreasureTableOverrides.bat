@echo off
SETLOCAL ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

REM ============================================================
REM  GenerateKnownVendorOverrides.bat
REM  - Genera un unico TreasureTableOverrided.txt con overrides
REM    SOLO para la lista de vendors conocida.
REM  - Por defecto NO toca AARDI_OBJ_Chest_Armoury (cofre/tutorial).
REM ============================================================

REM === Config ===
SET "OUTFILE=TreasureTableOverrided.txt"
SET "INCLUDE_ROOT_CHEST=0"  REM <-- Pone 1 si TAMBIEN queres vaciar AARDI_OBJ_Chest_Armoury
REM ==========================

REM Lista curada de vendors (sin duplicados)
SET Vendors=DEN_Volo_Trade DEN_Entrance_Trade DEN_Weaponsmith_Trade LOW_Weaponsmith_Trade UND_SocietyOfBrilliance_Hobgoblin CRE_Expeditioner_Trade CRE_GithQuartermistress_Trade MOO_InfernalTrader_Trade HAV_HarperQuarterMaster_Magic_Trade LOW_SorcerousSundries_Trade_Magic LOW_DevilsFee_Diabolist_Trade_Magic LOW_SteepsTrader_Weapons WYR_Thiefling_Trade

IF "%INCLUDE_ROOT_CHEST%"=="1" (
  SET Vendors=AARDI_OBJ_Chest_Armoury %Vendors%
)

IF EXIST "%OUTFILE%" DEL "%OUTFILE%" >NUL 2>&1

SET "count=0"
FOR %%V IN (%Vendors%) DO (
  REM Evitar duplicados por si alguien repite nombres
  FINDSTR /C:"new treasuretable \"%%V\"" "%OUTFILE%" >NUL 2>&1
  IF ERRORLEVEL 1 (
    >>"%OUTFILE%" ECHO new treasuretable "%%V"
    >>"%OUTFILE%" ECHO CanMerge 0
    SET /A count+=1
  )
)

ECHO.
IF "%count%"=="0" (
  ECHO No se generaron overrides (lista vacia?).
) ELSE (
  ECHO → Se generaron %count% overrides en: %OUTFILE%
  ECHO Copia este archivo a: Data\Public\TreasureTables\
  ECHO Asegurate que tu mod cargue DESPUES del mod que agrega los items.
)
PAUSE >NUL
