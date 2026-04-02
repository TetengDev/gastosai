package com.teng.app.gastosai.config;

import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.web.client.RestClient;

@Configuration
@EnableConfigurationProperties(OpenAiProperties.class)
public class OpenAiClientConfig {

	@Bean
	public RestClient openAiRestClient(OpenAiProperties properties) {
		return RestClient.builder()
				.baseUrl("https://api.openai.com")
				.defaultHeader(HttpHeaders.CONTENT_TYPE, MediaType.APPLICATION_JSON_VALUE)
				.requestInterceptor((request, body, execution) -> {
					String key = properties.getApiKey();
					if (key != null && !key.isBlank()) {
						request.getHeaders().setBearerAuth(key);
					}
					return execution.execute(request, body);
				})
				.build();
	}
}
