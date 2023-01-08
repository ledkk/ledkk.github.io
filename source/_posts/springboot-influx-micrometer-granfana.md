---
title: springboot_influx_micrometer_granfana
date: 2023-01-08 20:07:08
tags:
---

spring-boot-actuator 内部提供了很多autoconfiguration的实现，只要引入响应的jar包，就可以直接进行使用，这里分析Influx的使用方式
1. InfluxMetricsExportAutoConfiguration 提供了InfluxMetricsExport的配置引入, 进而提供了`InfluxMeterRegistry`的初始化
```java

@AutoConfiguration(
		before = { CompositeMeterRegistryAutoConfiguration.class, SimpleMetricsExportAutoConfiguration.class },
		after = MetricsAutoConfiguration.class)
@ConditionalOnBean(Clock.class)
@ConditionalOnClass(InfluxMeterRegistry.class)
@ConditionalOnEnabledMetricsExport("influx")
@EnableConfigurationProperties(InfluxProperties.class)
public class InfluxMetricsExportAutoConfiguration {

	private final InfluxProperties properties;

	public InfluxMetricsExportAutoConfiguration(InfluxProperties properties) {
		this.properties = properties;
	}

	@Bean
	@ConditionalOnMissingBean
	public InfluxConfig influxConfig() {
		return new InfluxPropertiesConfigAdapter(this.properties);
	}

	@Bean
	@ConditionalOnMissingBean
	public InfluxMeterRegistry influxMeterRegistry(InfluxConfig influxConfig, Clock clock) {
		return InfluxMeterRegistry.builder(influxConfig).clock(clock).httpClient(
				new HttpUrlConnectionSender(this.properties.getConnectTimeout(), this.properties.getReadTimeout()))
				.build();

	}

}

```

2. `InfluxMeterRegistry` 内部提供了线程池，会按照InfluxProperties 配置的相关参数，定时发布相关的指标到Influx中
```java

    private InfluxMeterRegistry(InfluxConfig config, Clock clock, ThreadFactory threadFactory, HttpSender httpClient) {
        super(config, clock);
        config().namingConvention(new InfluxNamingConvention());
        this.config = config;
        this.httpClient = httpClient;
        start(threadFactory);
    }

```

3. metrics发布相关的处理逻辑

```java

protected void publish() {
        createDatabaseIfNecessary();

        try {
            String influxEndpoint = config.apiVersion().writeEndpoint(config);

            for (List<Meter> batch : MeterPartition.partition(this, config.batchSize())) {
                HttpSender.Request.Builder requestBuilder = httpClient.post(influxEndpoint)
                        .withBasicAuthentication(config.userName(), config.password());
                config.apiVersion().addHeaderToken(config, requestBuilder);
                // @formatter:off
                requestBuilder
                        .withPlainText(batch.stream()
                                .flatMap(m -> m.match(
                                        gauge -> writeGauge(gauge.getId(), gauge.value()),
                                        counter -> writeCounter(counter.getId(), counter.count()),
                                        this::writeTimer,
                                        this::writeSummary,
                                        this::writeLongTaskTimer,
                                        gauge -> writeGauge(gauge.getId(), gauge.value(getBaseTimeUnit())),
                                        counter -> writeCounter(counter.getId(), counter.count()),
                                        this::writeFunctionTimer,
                                        this::writeMeter))
                                .collect(joining("\n")))
                        .compressWhen(config::compressed)
                        .send()
                        .onSuccess(response -> {
                            logger.debug("successfully sent {} metrics to InfluxDB.", batch.size());
                            databaseExists = true;
                        })
                        .onError(response -> logger.error("failed to send metrics to influx: {}", response.body()));
                // @formatter:on
            }
        }
        catch (MalformedURLException e) {
            throw new IllegalArgumentException(
                    "Malformed InfluxDB publishing endpoint, see '" + config.prefix() + ".uri'", e);
        }
        catch (Throwable e) {
            logger.error("failed to send metrics to influx", e);
        }
    }

```

4. 实际使用过程中，springboot会自动注入`InfluxMeterRegistry`，利用该对象可以注册新的指标数据

```java

@RestController
public class MicrometerTestController {

    private final MeterRegistry registry;

    //自动注入InfluxMeterRegistry
    public MicrometerTestController(MeterRegistry registry) {
        this.registry = registry;
    }

    @GetMapping("api/greet")
    public String greet() {
        //数据计数
        registry.counter("custom.greet","appname","BUYERS_APP","ip","192.168.0.68").increment();
        return "hello ";
    }
}

```

# Meter的类型
1. 计数器
计数器用来表示计数类监控项目，比如“控制器的访问次数”，“方法的调用次数”等等，这类监控信息都是只增不减的，且和次数有关

```java
// 利用Register获取Counter对象，并计数
registry.counter("custom.greet","appname","test","ip","192.168.0.68").increment();

// Counter builder 进行创建
Counter.builder("custom.greet").tag("appname","test").tag("ip","192.168.0.68").register(registry).increment();
```

2. 计量器

计量器用于持续计量类的任务，比如“集合长度”、“加载了类的个数”、“最大访问时间”等等。

registry.gauge("db.cpu",Math.random());



ref ： https://www.cnblogs.com/cjsblog/p/11556029.html

# 阿里云数据访问

接口调用基本已经可以使用了，主要遇到时间格式的问题，时间格式需要注意为UTC时间

```java
@SpringBootTest
class RdsServiceTest {

    @Autowired
    private RdsService rdsService;
    public String instanceId = "rm-bp13k1gnlgt9g8365";

    @Test
    void describeDBInstancePerformance() throws Exception {

        Date startTime = new Date(System.currentTimeMillis() - 1*60*60*1000);
        Date endTime = new Date(System.currentTimeMillis());
        // SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm'Z'");
        // sdf.setTimeZone(SimpleTimeZone.getTimeZone("UTC"));
        // sdf.format(startTime)
        List<String> performanceKeys = Lists.newArrayList("MySQL_NetworkTraffic","MySQL_InnoDBBufferRatio","MySQL_IOPS","MySQL_DetailedSpaceUsage");
        DescribeDBInstancePerformanceResponse describeDBInstancePerformanceResponse = rdsService.describeDBInstancePerformance(instanceId,performanceKeys, startTime, endTime);
        System.out.println(describeDBInstancePerformanceResponse.body);
        System.out.println(new Gson().toJson(describeDBInstancePerformanceResponse));
    }

    @Test
    void describeDBInstanceAttribute() throws Exception {
        DescribeDBInstanceAttributeResponse describeDBInstanceAttributeResponse = rdsService.describeDBInstanceAttribute(instanceId);
        System.out.println(new Gson().toJson(describeDBInstanceAttributeResponse));
    }

    @Test
    void describeResourceUsage() throws Exception {
        DescribeResourceUsageResponse describeResourceUsageResponse = rdsService.describeResourceUsage(instanceId);
        System.out.println(new Gson().toJson(describeResourceUsageResponse));
    }
}
```



