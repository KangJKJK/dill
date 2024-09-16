#!/bin/bash

# 색깔 변수 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Dill 노드 설치를 시작합니다.${NC}"

# 파일 경로 설정
DIRECTORY="/root/dill/validator_keys"
FILE_PATTERN="deposit_data-*.json"

# 현재 디렉토리 설정
_ROOT="$(pwd)" && cd "$(dirname "$0")" && ROOT="$(pwd)"
PJROOT="$ROOT"
DILL_DIR="$PJROOT/dill"

# 기본값으로 다운로드 설정
download=1
if [ $# -ge 1 ]; then
    download=$1
fi

version="v1.0.3"

# dill 노드 실행 함수
function launch_dill() {
    
    # OS 종류 확인
    os_type=$(uname)   # Darwin 또는 Linux 반환
    chip=$(uname -m)
    
    # 파일 및 URL 정의
    dill_darwin_file="dill-$version-darwin-arm64.tar.gz"
    dill_linux_file="dill-$version-linux-amd64.tar.gz"
    DILL_DARWIN_ARM64_URL="https://dill-release.s3.ap-southeast-1.amazonaws.com/$version/$dill_darwin_file"
    DILL_LINUX_AMD64_URL="https://dill-release.s3.ap-southeast-1.amazonaws.com/$version/$dill_linux_file"

    # macOS인지 확인
    if [ "$os_type" == "Darwin" ]; then
        if [ "$chip" == "arm64" ]; then
            echo "지원됨, OS: $os_type, 칩: $chip"
            if [ "$download" != "0" ]; then
                curl -O $DILL_DARWIN_ARM64_URL
                tar -zxvf $dill_darwin_file
            fi
        else
            echo "지원되지 않음, OS: $os_type, 칩: $chip"
            exit 1
        fi
    else
        # Linux인지 확인
        if [ "$chip" == "x86_64" ] && [ -f /etc/os-release ]; then
            # CPU에 필요한 명령어 세트가 있는지 확인
            if ! grep -qi "flags.*:.*adx" /proc/cpuinfo; then
                echo "경고: CPU에 필요한 명령어 세트 확장이 없으며 정상적으로 실행되지 않을 수 있습니다."
                echo "그래도 시도할 수 있습니다. 계속하려면 아무 키나 누르세요..."
                read -n 1 -s -r
            fi

            # OS 정보 가져오기
            source /etc/os-release
            if [ "$ID" == "ubuntu" ]; then
                major_version=$(echo $VERSION_ID | cut -d. -f1)
                if [ $major_version -ge 20 ]; then
                    echo "지원됨, OS: $ID $VERSION_ID, 칩: $chip"; echo ""
                    if [ "$download" != "0" ]; then
                        curl -O $DILL_LINUX_AMD64_URL
                        tar -zxvf $dill_linux_file
                    fi
                else
                    echo "지원되지 않음, OS: $ID $VERSION_ID (ubuntu 20.04+ 필요)"
                    exit 1
                fi
            else
                echo "지원되지 않음, OS: $os_type, 칩: $chip, $ID $VERSION_ID"
                exit 1
            fi
        else
            echo "지원되지 않음, OS: $os_type, 칩: $chip"
            exit 1
        fi
    fi
    
    # dill 노드 실행 스크립트 호출
    $DILL_DIR/1_launch_dill_node.sh
}

# 검증자 추가 함수
function add_validator() {
    $DILL_DIR/2_add_validator.sh
}

# 사용자에게 선택지 제공
read -p "${RED}입금주소와 출금주소는 같아야 편합니다. 설치진행 전에 하나의 wallet을 준비해두세요"
while true; do
    read -p "${YELLOW}원하는 작업을 선택하세요 [1. 새로운 dill 노드 실행 2. 기존 노드에 검증자 추가] [1]${NC}: " purpose
    purpose=${purpose:-1}  # 기본값으로 1 설정
    case "$purpose" in
        "1")
            launch_dill
            break
            ;;
        "2")
            add_validator
            break 
            ;;
        *)
            echo ""
            echo "[오류] $purpose 은(는) 유효한 옵션이 아닙니다."
            ;;
    esac
done

# Faucet 받기
echo -e "${GREEN}Faucet 작업을 시작합니다.${NC}"
echo -e "${YELLOW}Galxe 퀘스트를 완료하여 Dsicord Role을 획득하세요${NC}"
echo -e "${YELLOW}https://app.galxe.com/quest/Dill/GCgJAtvF1h?referral_code=GRFr2Jksp6m_3iKpJtfBbCz3bX1f64ar8En8fAfyI8cPWs9${NC}"
read -p "${GREEN}Galxe 퀘스트를 완료하셨습니까? (계속하려면 엔터를 누르세요)"

echo -e "${YELLOW}Dsicord 내부의 'alps'채널로 이동하여 Faucet을 받으세요${NC}"
echo -e "${YELLOW}https://discord.gg/dill${NC}"
read -p "${GREEN}Faucet을 받으셨으면 엔터를 누르세요"

# 파일 존재 여부 확인 및 출력
if [ -f "$DEPOSIT_FILE" ]; then
    echo "다음은 $DEPOSIT_FILE 파일의 내용입니다.(디파짓월렛):"
    echo "--------------------------------------------"
    cat "$DEPOSIT_FILE"  # 파일 내용 출력
    echo "--------------------------------------------"
    echo ""
    echo "위 내용을 모두 복사하세요."
    read -p "모두 복사한 후 계속하려면 엔터를 누르세요."
else
    echo "해당 파일을 찾을 수 없습니다: $FILE_PATTERN"
    exit 1
fi

# 검증자 되기
echo -e "${GREEN}검증자가 되는 작업을 시작합니다.${NC}"
echo -e "${YELLOW}해당사이트에 접속하여 'Upload deposit data'에 위 내용을 모두 복사하여 붙여넣으세요.${NC}"
echo -e "${YELLOW}https://staking.dill.xyz/${NC}"
read -p "${GREEN}내용을 모두 넣으신 다음 다음을 누르세요"

echo -e "${YELLOW}설정한 wallet과 동일한 메타마스크를 사용하여 지갑을 연결하세요.${NC}"
echo -e "${YELLOW}입급주소와 출금주소가 같다면 체크박스를 클릭하기만하여 확인만 하세요.${NC}"
read -p "${GREEN}SEND DEPOSIT을 클릭하시고 엔터를 누르세요."

echo -e "${GREEN}검증자 정보는 여기에서 확인할 수 있습니다: https://alps.dill.xyz/validators${NC}"
echo -e "${GREEN}모든 작업이 완료되었습니다. 컨트롤+A+D로 스크린을 종료해주세요.${NC}"
echo -e "${GREEN}스크립트 작성자: https://t.me/kjkresearch${NC}"
