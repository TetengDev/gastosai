package com.teng.app.gastosai.config;

import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;

import java.math.BigDecimal;

@ConfigurationProperties(prefix = "gastos.ai.cost")
@Getter
@Setter
public class AiCostProperties {

    private BigDecimal inputPerMtokUsd = new BigDecimal("0.15");
    private BigDecimal outputPerMtokUsd = new BigDecimal("0.60");
}
