package com.teng.app.gastosai.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "gastos.openai")
public class OpenAiProperties {

	private String apiKey = "";
	private String model = "gpt-4o-mini";

	public String getApiKey() {
		return apiKey;
	}

	public void setApiKey(String apiKey) {
		this.apiKey = apiKey != null ? apiKey : "";
	}

	public String getModel() {
		return model;
	}

	public void setModel(String model) {
		this.model = (model == null || model.isBlank()) ? "gpt-4o-mini" : model;
	}
}
