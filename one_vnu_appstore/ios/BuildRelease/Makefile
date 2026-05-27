VALID_METHODS := app-store ad-hoc
method ?= app-store
app_store_connect_api_key_id := 244TDZ3GCF
app_store_connect_api_issuer_id := de9eb225-5156-4abc-b2fe-9be2d86c435f

ipa:
ifeq ($(filter $(method),$(VALID_METHODS)),)
    $(info $(method) does not exist in $(VALID_METHODS))
endif
	fastlane gym \
		--verbose \
		--workspace "../Runner.xcworkspace" --scheme "Runner" --clean \
		--output_directory "./build" \
		--output_name "Runner-$(method)" \
		--sdk "iphoneos18.1" \
		--include_symbols false \
		--export_options $(method)-export-options.plist

validate:
	xcrun altool \
		--validate-app \
		-t ios \
		--file "build/Runner-$(method).ipa" \
		--apiKey "$(app_store_connect_api_key_id)" \
		--apiIssuer "$(app_store_connect_api_issuer_id)" 

upload:
	xcrun altool \
		--upload-app \
		-t ios \
		--file "build/Runner-$(method).ipa" \
		--apiKey "$(app_store_connect_api_key_id)" \
		--apiIssuer "$(app_store_connect_api_issuer_id)" 
	
