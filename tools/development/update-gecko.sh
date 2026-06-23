#!/bin/zsh

set -euo pipefail

SCRIPT_DIR="${0:A:h}"
ROOT_DIR="${SCRIPT_DIR:h:h}"
SUBMODULE_PATH="engine/firefox"
FIREFOX_URL="https://github.com/mozilla-firefox/firefox"

cd "$ROOT_DIR"

if [[ ! -f "engine/release.txt" ]]; then
	echo "Cannot get Firefox release tag: Missing engine/release.txt."
	exit 1
fi

RELEASE_TAG="$(tr -d '\000\r' < "engine/release.txt" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')"

if [[ -z "$RELEASE_TAG" ]]; then
	echo "Cannot get Firefox release tag: engine/release.txt is empty."
	exit 1
fi

if ! git ls-remote --exit-code --tags "$FIREFOX_URL" "refs/tags/$RELEASE_TAG" >/dev/null 2>&1; then
	echo "Release tag $RELEASE_TAG does not exist in $FIREFOX_URL."
	exit 1
fi

TAG_REF="refs/tags/$RELEASE_TAG"

# 检查目录是否是有效的 git 仓库
if [[ ! -d "$SUBMODULE_PATH/.git" ]]; then
	echo "$SUBMODULE_PATH is not a git repository. Cloning shallowly..."
	# 如果目录已存在但不是 git 仓库，先清理
	if [[ -d "$SUBMODULE_PATH" ]]; then
		rm -rf "$SUBMODULE_PATH"
	fi
	# 浅克隆指定 tag
	git clone --depth 1 --branch "$RELEASE_TAG" --single-branch "$FIREFOX_URL" "$SUBMODULE_PATH"
	echo "Clone complete."
else
	echo "Updating existing repository at $SUBMODULE_PATH"
	# 确保 remote url 正确
	git -C "$SUBMODULE_PATH" remote set-url origin "$FIREFOX_URL"
	# 抓取指定 tag
	echo "Fetching and checking out tag $RELEASE_TAG..."
	git -C "$SUBMODULE_PATH" fetch --depth 1 origin tag "$RELEASE_TAG"
	git -C "$SUBMODULE_PATH" checkout --detach "$TAG_REF^{commit}"
fi

EXPECTED_COMMIT="$(git -C "$SUBMODULE_PATH" rev-parse "$TAG_REF^{commit}")"
HEAD_COMMIT="$(git -C "$SUBMODULE_PATH" rev-parse HEAD)"

if [[ "$HEAD_COMMIT" != "$EXPECTED_COMMIT" ]]; then
	echo "Failed to checkout the expected commit for $RELEASE_TAG."
	echo "Expected: $EXPECTED_COMMIT"
	echo "Actual:   $HEAD_COMMIT"
	exit 1
fi
