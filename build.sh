#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Emojis
CHECK="\xE2\x9C\x85"    # ✅
CROSS="\xE2\x9D\x8C"     # ❌
BOOK="\xF0\x9F\x93\x96"  # 📖

# strings
EXPORT=$(cat build-config.yml | yq '.export-name')

# Progress bar function
progress_bar() {
  local current=$1
  local total=$2
  local width=40  # Width of the progress bar
  local progress=$((current * width / total))
  local remainder=$((width - progress))

  # Create the visual bar
  bar=$(printf "%${progress}s" | tr ' ' '#')
  space=$(printf "%${remainder}s" | tr ' ' '-')
  
  printf "\r${BLUE}Compiling LaTeX: [%s%s] %d/%d${NC}" "$bar" "$space" "$current" "$total"
}

# Compute the new hash
sha1sum contents/* | sha1sum > temp

# Check if hash.txt exists and compare hashes
if [[ ! -f $EXPORT ]]; then
  echo -e "${YELLOW}${BOOK} ${EXPORT} not found. Building it from source...${NC}"
  mv temp hash.txt
elif [[ ! -f hash.txt ]]; then
  echo -e "${YELLOW}${BOOK} hash.txt not found. Creating it and rebuilding...${NC}"
  mv temp hash.txt
elif diff hash.txt temp > /dev/null; then
  echo -e "${GREEN}${CHECK} Hashes are the same. No need to rebuild!${NC}"
  rm temp
  exit 0
else
  echo -e "${YELLOW}${CROSS} Hashes are different. Rebuilding...${NC}"
  mv temp hash.txt
fi

# Perform LaTeX compilation if needed
if [[ ! -f temp ]]; then
  for i in $(seq 1 $1); do
    progress_bar $i $1
    pdflatex -halt-on-error --shell-escape main.tex > /dev/null 2>&1
    if [[ $? -ne 0 ]]; then
      echo -e "\n${RED}${CROSS} Build failed!${NC}"
      exit 1
    fi
  done
  echo -e "\n${GREEN}${CHECK} Compilation complete!${NC}"

  mv main.pdf $EXPORT
  echo -e "${GREEN}${CHECK} Moved file to ${EXPORT}!${NC}"

  # Cleanup temporary files
  rm */*.aux *.aux */*.log *.log */*.out *.out

  echo -e "${GREEN}${CHECK} Cleanup complete!${NC}"
fi

