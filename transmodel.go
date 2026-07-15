package main

import (
	"encoding/json"
	"fmt"
)

func main() {
	insert_test()
}

// var jsonString string = `{"name": "London"}`
var jsonString string = ""

func insert_test() {
	// CREATE  OR REPLACE FUNCTION network.insert_zone(p_code VARCHAR, p_name VARCHAR, p_updated_by VARCHAR DEFAULT CURRENT_USER) RETURNS BIGINT AS $$
	_result, _err := GenerateStoredProcWrapper("network", "get_all_zones", jsonString)
	if _err == nil {
		fmt.Printf("\n%s\n", _result)
	} else {
		fmt.Printf("error = %s\n", _err)
	}
}

// ============================================================================
// This function generates a stored procedure wrapper given a
// procedure name and a sample json input
// ============================================================================
func GenerateStoredProcWrapper(schema string, procName string, jsonInput string) (string, error) {
	var _data map[string]interface{}
	var _output string
	var _err error

	if len(jsonInput) > 0 {
		_err = json.Unmarshal([]byte(jsonInput), &_data)
	}
	if _err == nil {
		if len(jsonInput) > 0 {
			_output = fmt.Sprintf("CREATE OR REPLACE FUNCTION %s.J%s (input json) RETURNS text AS $$\n    DECLARE\n", schema, procName)
		} else {
			_output = fmt.Sprintf("CREATE OR REPLACE FUNCTION %s.J%s () RETURNS text AS $$\n    DECLARE\n", schema, procName)
		}
		_output, _ = generateParamsFromMap("", _output, _data)
		_output += "        _result TEXT;\n"
		_output += "    BEGIN\n"
		_output += "        -- function body here\n"
		_output += "        RETURN _result;\n"
		_output += "    END;\n"
		_output += "$$ LANGUAGE plpgsql;\n"
	}
	return _output, _err
}

// ============================================================================
// this is a recursive function to handle nested json objects
// This is how you get individual values from nested json in psql:
// _contacts_email TEXT := input::json#>>'{contacts, email}';
// ============================================================================
func generateParamsFromMap(prefix, output string, _data map[string]any) (string, error) {
	if prefix == "" {
		prefix = "v" + prefix
	}
	for _key, _value := range _data {
		switch v := _value.(type) {
		case string:
			output += fmt.Sprintf("        %s_%s TEXT := input::json->>'%s';\n", prefix, _key, _key)
		case float64:
			output += fmt.Sprintf("        %s_%s NUMERIC := (input::json->>'%s')::NUMERIC;\n", prefix, _key, _key)
		case bool:
			output += fmt.Sprintf("        %s_%s BOOLEAN := (input::json->>'%s')::BOOLEAN;\n", prefix, _key, _key)
		case map[string]any:
			output, _ = generateParamsFromMap(prefix+"_"+_key, output, _value.(map[string]any))
		default:
			return "", fmt.Errorf("unsupported type for key %s: %T", _key, v)
		}
	}
	return output, nil
}
