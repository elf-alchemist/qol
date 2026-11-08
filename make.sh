#!/usr/bin/env bash

# Stricter shell handling
set -euo pipefail

if ! command -v zip &>/dev/null; then
  echo "ZIP not found!"
  echo "Make sure you have the 'zip' command installed."
  exit 1
fi

# Setup functions
IDENT_LEVEL=0

function IndentFurther {
  IDENT_LEVEL=$((IDENT_LEVEL + 1))
}

function IndentBack {
  IDENT_LEVEL=$((IDENT_LEVEL - 1))
}

function Logger {
  printf "%$((IDENT_LEVEL * 2))s%s\n" "" "$1"
}

SRC="${PWD}/src"
INFO="${PWD}/info"
SCRIPTS="${PWD}/scripts"
BUILD="${PWD}/build"
DIST="${PWD}/dist"

REV_COUNT="$(git rev-list --count HEAD)"
SIMPLECPP="${SCRIPTS}/simplecpp.py"

function CleanBuild {
  rm -r "${BUILD}" || true
  rm -r "${DIST}" || true
}

function CopyFile {
  local SRC_TARGET="$1"
  local DEST_TARGET="$2"
  local SRC_DIR
  local SRC_PARENT

  SRC_DIR="$(basename -- "${SRC_TARGET}")"
  SRC_PARENT="$(basename -- "$(dirname -- "$(realpath -- "${SRC_TARGET}")")")"
  local SRC_AND_PARENT="${SRC_PARENT}/${SRC_DIR}"

  if [[ -f "${SRC_TARGET}" ]]; then
    Logger "Copying file ${SRC_AND_PARENT}"
    cp "${SRC_TARGET}" "${DEST_TARGET}"
  else
    Logger "Source file ${SRC_AND_PARENT} does not exist or is not a file - can't copy."
  fi
}

function CopyDirectory {
  local SRC_TARGET="$1"
  local DEST_TARGET="$2"
  local SRC_DIR
  local SRC_PARENT

  SRC_DIR="$(basename -- "${SRC_TARGET}")"
  SRC_PARENT="$(basename -- "$(dirname -- "$(realpath -- "${SRC_TARGET}")")")"
  local SRC_AND_PARENT="${SRC_PARENT}/${SRC_DIR}"

  if [[ -d "${SRC_TARGET}" ]]; then
    Logger "Copying directory over ${SRC_AND_PARENT}"
    cp -r "${SRC_TARGET}" "${DEST_TARGET}"
  else
    Logger "Source directory ${SRC_AND_PARENT} does not exist or is not a directory - can't copy."
  fi
}

function CopyDirectoryContents {
  local SRC_TARGET="$1"
  local DEST_TARGET="$2"
  local SRC_DIR
  local SRC_PARENT
  local DEST_DIR
  local DEST_PARENT

  SRC_DIR="$(basename -- "${SRC_TARGET}")"
  SRC_PARENT="$(basename -- "$(dirname -- "$(realpath -- "${SRC_TARGET}")")")"
  DEST_DIR="$(basename -- "${DEST_TARGET}")"
  DEST_PARENT="$(basename -- "$(dirname -- "$(realpath -- "${DEST_TARGET}")")")"
  local SRC_AND_PARENT="${SRC_PARENT}/${SRC_DIR}"
  local DEST_AND_PARENT="${DEST_PARENT}/${DEST_DIR}"

  if [[ -d "${SRC_TARGET}" ]]; then
    Logger "Copying over contents of ${SRC_AND_PARENT} to ${DEST_AND_PARENT}"
    mkdir -p "${DEST_TARGET}"
    cp -r "${SRC_TARGET}/." "${DEST_TARGET}/"
  else
    Logger "Source directory ${SRC_AND_PARENT} does not exist or is not a directory - can't copy."
  fi
}

function MakeDateTimeFile
{
  local DIR_TARGET="$1"
  local FILE_TARGET="$2"
  local TARGET="${DIR_TARGET}/${FILE_TARGET}"
  echo -n "$(date -u -Iseconds)" >> "${TARGET}"
}

function MakeDateFile
{
  local DIR_TARGET="$1"
  local FILE_TARGET="$2"
  local TARGET="${DIR_TARGET}/${FILE_TARGET}"
  echo -n "$(date -u -I)" >> "${TARGET}"
}

function MakeZIP {
  local SRC_TARGET="$1"
  local DEST_TARGET="$2"
  local SRC_DIR
  local SRC_PARENT
  local DEST_DIR
  local DEST_PARENT

  SRC_DIR="$(basename -- "${SRC_TARGET}")"
  SRC_PARENT="$(basename -- "$(dirname -- "$(realpath -- "${SRC_TARGET}")")")"
  DEST_DIR="$(basename -- "${DEST_TARGET}")"
  DEST_PARENT="$(basename -- "$(dirname -- "$(realpath -- "${DEST_TARGET}")")")"
  local SRC_AND_PARENT="${SRC_PARENT}/${SRC_DIR}"
  local DEST_AND_PARENT="${DEST_PARENT}/${DEST_DIR}"

  IndentFurther
  Logger "Moving to ${SRC_AND_PARENT}"
  cd "${SRC_TARGET}"

  IndentFurther
  Logger "Making ${DEST_AND_PARENT}"
  find . -type f | sort | zip "${DEST_TARGET}" -@ &> /dev/null
  IndentBack

  cd - &> /dev/null
  IndentBack
}

# Actual work

Logger "Cleaning up..."

CleanBuild

Logger "Starting build setup..."

mkdir -p "${BUILD}"
mkdir -p "${DIST}"

FILENAME="qol_r${REV_COUNT}"

BUILD_QOL="$(realpath "${BUILD}/qol")"
DIST_QOL="$(realpath "${DIST}/${FILENAME}.pk3")"

BUILD_INFO="$(realpath "${BUILD}/info")"
DIST_INFO="$(realpath "${DIST}/${FILENAME}.txt")"

IndentFurther
#START

# Base files
CopyDirectory "${SRC}" "${BUILD_QOL}"
MakeDateTimeFile "${BUILD_QOL}" "__VER__.txt"

# Special handling of WADINFO.txt
CopyDirectory "${INFO}" "${BUILD_INFO}"

# Get filename per-build
FILENAME_STR="Filename                : ${FILENAME}.pk3" 
echo "${FILENAME_STR}" >> "${BUILD_INFO}/Filename.txt"

# Get build date per-build
echo -n "Release date            : " >> "${BUILD_INFO}/Release_Date.txt"
MakeDateFile "${BUILD_INFO}" "Release_Date.txt"
echo ""                              >> "${BUILD_INFO}/Release_Date.txt"

# Compile it
cd "${BUILD_INFO}"
WADINFO="$(cat < "WADINFO.template.txt" | python3 "${SIMPLECPP}")"
echo "${WADINFO}" >> "${BUILD_INFO}/${FILENAME}.txt"

CopyFile "${BUILD_INFO}/${FILENAME}.txt" "${DIST_INFO}"
CopyFile "${BUILD_INFO}/${FILENAME}.txt" "${BUILD_QOL}/WADINFO.txt"

#END
IndentBack

# Finally, compile it all
Logger "Bundling for distribution..."
MakeZIP "${BUILD_QOL}" "${DIST_QOL}"
Logger "Finished building mod!"
