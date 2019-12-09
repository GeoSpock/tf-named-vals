// MIT license
// Copyright (c) 2019 GeoSpock Ltd.

package main

import (
	"encoding/json"
	"fmt"
	"strings"
	"os"
	"log"

	"github.com/hashicorp/terraform/configs"
	"github.com/hashicorp/terraform/configs/hcl2shim"

	"github.com/urfave/cli/v2"
)

func main() {
	app := &cli.App{
		Name: "tf-named-vals",
		Version: VERSION,
		Usage: "get named values from Terraform HCL (both version 1 and 2) files",
		Commands: []*cli.Command{
			{
				Name:    "all-as-json",
				Aliases: []string{"a"},
				Usage:   "output all named values from a .tf file as JSON",
				ArgsUsage: "TF-FILE",
				Action:  func(c *cli.Context) error {

					var err error
					var json []byte

					json, err = toJSON(c.Args().First())

					if err != nil {
						fmt.Fprintln(os.Stderr, err)
						os.Exit(1)
					}

					fmt.Println(string(json))


					return nil
				},
			},
		},
	}


	err := app.Run(os.Args)
	if err != nil {
		log.Fatal(err)
	}

}

func toJSON(filename string) ([]byte, error) {

	p := configs.NewParser(nil)

	f, diags := p.LoadConfigFile(filename)

	if diags.HasErrors() {

		var diags_details []string
		for _, diag := range diags {
			diags_details = append(diags_details, fmt.Sprintf("%s: %s", diag.Subject, diag.Detail))
		}
		return nil, fmt.Errorf("Errors during the load of %s:\n%s", filename, strings.Join(diags_details, ",\n"))
	}


	var variables []map[string]interface{}

	for i := range f.Variables {

		def_val, err := json.Marshal(hcl2shim.ConfigValueFromHCL2(f.Variables[i].Default))
		raw_def_val := json.RawMessage(def_val)

		if err != nil {
			return nil, fmt.Errorf("Unable to marshal the variable default value JSON: %s", err)
		}

		var_type, err := f.Variables[i].Type.MarshalJSON()
		if err != nil {
			return nil, fmt.Errorf("Unable to marshal the variable type JSON: %s", err)
		}
		raw_var_type := json.RawMessage(var_type)

		variable := make(map[string]interface{})
		variable["name"] = f.Variables[i].Name

		if f.Variables[i].DescriptionSet {
			variable["description"] = f.Variables[i].Description
		}
		variable["type"] = &raw_var_type
		variable["default"] = &raw_def_val

		variables = append(variables, variable)
	}

	var outputs []map[string]interface{}

	for i := range f.Outputs {
		output := make(map[string]interface{})

		output["name"] = f.Outputs[i].Name

		if f.Outputs[i].DescriptionSet {
			output["description"] = f.Outputs[i].Description
		}
		output["value"] = string(f.Outputs[i].Expr.Range().SliceBytes(p.Sources()[filename]))
		output["sensitive"] = f.Outputs[i].SensitiveSet

		outputs = append(outputs, output)
	}

	result := map[string][]map[string]interface{}{"variables": variables, "outputs": outputs}

	json_s, err := json.Marshal(result)

	if err != nil {
		return nil, fmt.Errorf("Unable to marshal JSON: %s", err)
	}

	return json_s, nil
}
