#!/usr/bin/env bash

# MIT license
# Copyright (c) 2019 GeoSpock Ltd.

__DOC__='Functional tests for tf-named-vals'

set -euo pipefail

# shellcheck disable=SC1091
source shelter.sh


TEMP_DIR=$(mktemp -d)

_cleanup () {
    rm -rf -- "${TEMP_DIR}/test_"*

    rmdir "$TEMP_DIR"

    if [[ "${#SAVED_EXIT_TRAP_CMD[@]}" -gt 0 ]]; then
        eval "${SAVED_EXIT_TRAP_CMD[2]}"
    fi
}

eval "declare -a SAVED_EXIT_TRAP_CMD=($(trap -p EXIT))"
trap _cleanup EXIT



test_full () {
    assert_stdout './tf-named-vals all-as-json e2e/main.tf | jq -S .' <<"EOF"
{
  "locals": {
    "l1": {
      "expression": "{\n    a = \"one\"\n    \"b\" = \"${var.var2}${var.var3}-l1\"\n  }"
    },
    "l2": {
      "expression": "var.var4"
    },
    "l3": {
      "expression": "\"test\""
    }
  },
  "outputs": {
    "bar": {
      "description": "Secret",
      "expression": "\"${local.var1[\"key1\"]}${var.var2}\"",
      "sensitive": true
    },
    "baz": {
      "expression": "\"value\"",
      "sensitive": false
    },
    "foo": {
      "expression": "var.var1",
      "sensitive": false
    }
  },
  "variables": {
    "var1": {
      "default": {
        "key1": "value1"
      },
      "description": "This is the var1 variable",
      "type": [
        "map",
        "string"
      ]
    },
    "var2": {
      "default": "value",
      "description": "This is the var2 variable",
      "type": "string"
    },
    "var3": {
      "default": "value",
      "type": "string"
    },
    "var4": {
      "default": "value",
      "type": "dynamic"
    },
    "var5": {
      "default": "value",
      "type": "dynamic"
    }
  }
}
EOF
}


test_empty () {
    assert_stdout './tf-named-vals all-as-json e2e/empty.tf | jq -S .' <<"EOF"
{
  "locals": {},
  "outputs": {},
  "variables": {}
}
EOF
}


test_hcl1 () {
    assert_stdout './tf-named-vals all-as-json e2e/hcl1.tf | jq -S .' <<"EOF"
{
  "locals": {},
  "outputs": {},
  "variables": {
    "hcl1_var": {
      "default": "test",
      "type": "string"
    }
  }
}
EOF
}


test_invalid () {
    assert_fail './tf-named-vals all-as-json e2e/invalid.tf 2>/dev/null'
}


test_vars_only () {
    assert_stdout './tf-named-vals all-as-json e2e/vars-only.tf | jq -S .' <<"EOF"
{
  "locals": {},
  "outputs": {},
  "variables": {
    "var6": {
      "default": "value",
      "description": "This is the var6 variable",
      "type": "string"
    },
    "var7": {
      "default": "value",
      "description": "This is the var7 variable",
      "type": "string"
    }
  }
}
EOF
}


test_outputs_only () {
    assert_stdout './tf-named-vals all-as-json e2e/outputs-only.tf | jq -S .' <<"EOF"
{
  "locals": {},
  "outputs": {
    "o1": {
      "expression": "\"value1\"",
      "sensitive": false
    },
    "o2": {
      "expression": "\"value2\"",
      "sensitive": false
    }
  },
  "variables": {}
}
EOF
}


test_locals_only () {
    assert_stdout './tf-named-vals all-as-json e2e/locals-only.tf | jq -S .' <<"EOF"
{
  "locals": {
    "l4": {
      "expression": "\"4\""
    },
    "l5": {
      "expression": "\"5\""
    },
    "l6": {
      "expression": "6"
    },
    "l7": {
      "expression": "\"7\""
    }
  },
  "outputs": {},
  "variables": {}
}
EOF
}



suite () {
    shelter_run_test_class All test_
}

usage () {
    cat <<EOF
Usage: ${0} [--help]
${__DOC__}
ENVIRONMENT VARIABLES:
  ENABLE_CI_MODE    set to non-empty value to enable the Junit XML
                    output mode
EOF
}

main () {
    if [[ "${1:-}" = '--help' ]]; then
        usage
        return 0
    fi

    supported_shelter_versions 0.7

    if [[ -n "${ENABLE_CI_MODE:-}" ]]; then
        mkdir -p junit
        shelter_run_test_suite suite | shelter_junit_formatter >junit/test_libautomated.xml
    else
        shelter_run_test_suite suite | shelter_human_formatter
    fi
}


if ! (return 2>/dev/null); then
    main "$@"
fi
