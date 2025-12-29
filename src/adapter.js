import { OpenAIResponsesApiService } from './openai/openai-responses-core.js'; // 导入OpenAIResponsesApiService
import { GeminiApiService } from './gemini/gemini-core.js'; // 导入geminiApiService
import { AntigravityApiService } from './gemini/antigravity-core.js'; // 导入AntigravityApiService
import { OpenAIApiService } from './openai/openai-core.js'; // 导入OpenAIApiService
import { ClaudeApiService } from './claude/claude-core.js'; // 导入ClaudeApiService
import { KiroApiService } from './claude/claude-kiro.js'; // 导入KiroApiService
import { QwenApiService } from './openai/qwen-core.js'; // 导入QwenApiService
import { MODEL_PROVIDER } from './common.js'; // 导入 MODEL_PROVIDER
import { EventEmitter } from 'events'; // 导入事件发射器

// 定义AI服务适配器接口
// 所有的服务适配器都应该实现这些方法
export class ApiServiceAdapter {
    constructor() {
        if (new.target === ApiServiceAdapter) {
            throw new TypeError("Cannot construct ApiServiceAdapter instances directly");
        }
    }

    /**
     * 生成内容
     * @param {string} model - 模型名称
     * @param {object} requestBody - 请求体
     * @returns {Promise<object>} - API响应
     */
    async generateContent(model, requestBody) {
        throw new Error("Method 'generateContent()' must be implemented.");
    }

    /**
     * 流式生成内容
     * @param {string} model - 模型名称
     * @param {object} requestBody - 请求体
     * @returns {AsyncIterable<object>} - API响应流
     */
    async *generateContentStream(model, requestBody) {
        throw new Error("Method 'generateContentStream()' must be implemented.");
    }

    /**
     * 列出可用模型
     * @returns {Promise<object>} - 模型列表
     */
    async listModels() {
        throw new Error("Method 'listModels()' must be implemented.");
    }

    /**
     * 刷新认证令牌
     * @returns {Promise<void>}
     */
    async refreshToken() {
        throw new Error("Method 'refreshToken()' must be implemented.");
    }
}

// Gemini API 服务适配器
export class GeminiApiServiceAdapter extends ApiServiceAdapter {
    constructor(config) {
        super();
        this.geminiApiService = new GeminiApiService(config);
        // this.geminiApiService.initialize().catch(error => {
        //     console.error("Failed to initialize geminiApiService:", error);
        // });
    }

    async generateContent(model, requestBody) {
        if (!this.geminiApiService.isInitialized) {
            console.warn("geminiApiService not initialized, attempting to re-initialize...");
            await this.geminiApiService.initialize();
        }
        return this.geminiApiService.generateContent(model, requestBody);
    }

    async *generateContentStream(model, requestBody) {
        if (!this.geminiApiService.isInitialized) {
            console.warn("geminiApiService not initialized, attempting to re-initialize...");
            await this.geminiApiService.initialize();
        }
        yield* this.geminiApiService.generateContentStream(model, requestBody);
    }

    async listModels() {
        if (!this.geminiApiService.isInitialized) {
            console.warn("geminiApiService not initialized, attempting to re-initialize...");
            await this.geminiApiService.initialize();
        }
        // Gemini Core API 的 listModels 已经返回符合 Gemini 格式的数据，所以不需要额外转换
        return this.geminiApiService.listModels();
    }

    async refreshToken() {
        if(this.geminiApiService.isExpiryDateNear()===true){
            console.log(`[Gemini] Expiry date is near, refreshing token...`);
            return this.geminiApiService.initializeAuth(true);
        }
        return Promise.resolve();
    }

    /**
     * 获取用量限制信息
     * @returns {Promise<Object>} 用量限制信息
     */
    async getUsageLimits() {
        if (!this.geminiApiService.isInitialized) {
            console.warn("geminiApiService not initialized, attempting to re-initialize...");
            await this.geminiApiService.initialize();
        }
        return this.geminiApiService.getUsageLimits();
    }
}

// Antigravity API 服务适配器
export class AntigravityApiServiceAdapter extends ApiServiceAdapter {
    constructor(config) {
        super();
        this.antigravityApiService = new AntigravityApiService(config);
    }

    async generateContent(model, requestBody) {
        if (!this.antigravityApiService.isInitialized) {
            console.warn("antigravityApiService not initialized, attempting to re-initialize...");
            await this.antigravityApiService.initialize();
        }
        return this.antigravityApiService.generateContent(model, requestBody);
    }

    async *generateContentStream(model, requestBody) {
        if (!this.antigravityApiService.isInitialized) {
            console.warn("antigravityApiService not initialized, attempting to re-initialize...");
            await this.antigravityApiService.initialize();
        }
        yield* this.antigravityApiService.generateContentStream(model, requestBody);
    }

    async listModels() {
        if (!this.antigravityApiService.isInitialized) {
            console.warn("antigravityApiService not initialized, attempting to re-initialize...");
            await this.antigravityApiService.initialize();
        }
        return this.antigravityApiService.listModels();
    }

    async refreshToken() {
        if (this.antigravityApiService.isExpiryDateNear() === true) {
            console.log(`[Antigravity] Expiry date is near, refreshing token...`);
            return this.antigravityApiService.initializeAuth(true);
        }
        return Promise.resolve();
    }

    /**
     * 获取用量限制信息
     * @returns {Promise<Object>} 用量限制信息
     */
    async getUsageLimits() {
        if (!this.antigravityApiService.isInitialized) {
            console.warn("antigravityApiService not initialized, attempting to re-initialize...");
            await this.antigravityApiService.initialize();
        }
        return this.antigravityApiService.getUsageLimits();
    }
}

// OpenAI API 服务适配器
export class OpenAIApiServiceAdapter extends ApiServiceAdapter {
    constructor(config) {
        super();
        this.openAIApiService = new OpenAIApiService(config);
    }

    async generateContent(model, requestBody) {
        // The adapter now expects the requestBody to be in the native OpenAI format.
        // The conversion logic is handled upstream in the server.
        return this.openAIApiService.generateContent(model, requestBody);
    }

    async *generateContentStream(model, requestBody) {
        // The adapter now expects the requestBody to be in the native OpenAI format.
        const stream = this.openAIApiService.generateContentStream(model, requestBody);
        // The stream is yielded directly without conversion.
        yield* stream;
    }

    async listModels() {
        // The adapter now returns the native model list from the underlying service.
        return this.openAIApiService.listModels();
    }

    async refreshToken() {
        // OpenAI API keys are typically static and do not require refreshing.
        return Promise.resolve();
    }
}

// OpenAI Responses API 服务适配器
export class OpenAIResponsesApiServiceAdapter extends ApiServiceAdapter {
    constructor(config) {
        super();
        this.openAIResponsesApiService = new OpenAIResponsesApiService(config);
    }

    async generateContent(model, requestBody) {
        // The adapter expects the requestBody to be in the OpenAI Responses format.
        return this.openAIResponsesApiService.generateContent(model, requestBody);
    }

    async *generateContentStream(model, requestBody) {
        // The adapter expects the requestBody to be in the OpenAI Responses format.
        const stream = this.openAIResponsesApiService.generateContentStream(model, requestBody);
        yield* stream;
    }

    async listModels() {
        // The adapter returns the native model list from the underlying service.
        return this.openAIResponsesApiService.listModels();
    }

    async refreshToken() {
        // OpenAI API keys are typically static and do not require refreshing.
        return Promise.resolve();
    }
}

// Claude API 服务适配器
export class ClaudeApiServiceAdapter extends ApiServiceAdapter {
    constructor(config) {
        super();
        this.claudeApiService = new ClaudeApiService(config);
    }

    async generateContent(model, requestBody) {
        // The adapter now expects the requestBody to be in the native Claude format.
        return this.claudeApiService.generateContent(model, requestBody);
    }

    async *generateContentStream(model, requestBody) {
        // The adapter now expects the requestBody to be in the native Claude format.
        const stream = this.claudeApiService.generateContentStream(model, requestBody);
        yield* stream;
    }

    async listModels() {
        // The adapter now returns the native model list from the underlying service.
        return this.claudeApiService.listModels();
    }

    async refreshToken() {
        return Promise.resolve();
    }
}

// Kiro API 服务适配器
export class KiroApiServiceAdapter extends ApiServiceAdapter {
    constructor(config) {
        super();
        this.kiroApiService = new KiroApiService(config);
        this.config = config;
        this.eventEmitter = new EventEmitter(); // 事件发射器用于广播token过期事件
        // this.kiroApiService.initialize().catch(error => {
        //     console.error("Failed to initialize kiroApiService:", error);
        // });
    }

    async generateContent(model, requestBody) {
        // The adapter expects the requestBody to be in OpenAI format for Kiro API
        if (!this.kiroApiService.isInitialized) {
            console.warn("kiroApiService not initialized, attempting to re-initialize...");
            await this.kiroApiService.initialize();
        }
        try {
            return await this.kiroApiService.generateContent(model, requestBody);
        } catch (error) {
            // Check if error is related to refreshToken expiration
            this._handleTokenError(error);
            throw error;
        }
    }

    async *generateContentStream(model, requestBody) {
        // The adapter expects the requestBody to be in OpenAI format for Kiro API
        if (!this.kiroApiService.isInitialized) {
            console.warn("kiroApiService not initialized, attempting to re-initialize...");
            await this.kiroApiService.initialize();
        }
        try {
            const stream = this.kiroApiService.generateContentStream(model, requestBody);
            yield* stream;
        } catch (error) {
            // Check if error is related to refreshToken expiration
            this._handleTokenError(error);
            throw error;
        }
    }

    async listModels() {
        // Returns the native model list from the Kiro service
        if (!this.kiroApiService.isInitialized) {
            console.warn("kiroApiService not initialized, attempting to re-initialize...");
            await this.kiroApiService.initialize();
        }
        return this.kiroApiService.listModels();
    }

    async refreshToken() {
        // Check if refreshToken itself is near expiration or has failed
        const refreshTokenStatus = this.kiroApiService.isRefreshTokenNearExpiry();
        if (refreshTokenStatus.isNear) {
            console.warn(`[Kiro Adapter] RefreshToken issue detected: ${refreshTokenStatus.reason}`);
            // Emit event for potential re-authorization
            this._emitRefreshTokenExpiry(refreshTokenStatus);
            // Don't attempt to refresh if refreshToken has failed
            if (refreshTokenStatus.hasFailed) {
                console.error('[Kiro Adapter] RefreshToken has failed, skipping refresh attempt');
                return Promise.resolve();
            }
        }

        // Check if accessToken is near expiration
        if(this.kiroApiService.isExpiryDateNear()===true){
            console.log(`[Kiro Adapter] AccessToken expiry date is near, refreshing token...`);
            try {
                return await this.kiroApiService.initializeAuth(true);
            } catch (error) {
                this._handleTokenError(error);
                throw error;
            }
        }
        return Promise.resolve();
    }

    /**
     * 获取用量限制信息
     * @returns {Promise<Object>} 用量限制信息
     */
    async getUsageLimits() {
        if (!this.kiroApiService.isInitialized) {
            console.warn("kiroApiService not initialized, attempting to re-initialize...");
            await this.kiroApiService.initialize();
        }
        return this.kiroApiService.getUsageLimits();
    }

    /**
     * 处理token相关错误，检测并广播refreshToken过期事件
     * @private
     * @param {Error} error - 捕获的错误对象
     */
    _handleTokenError(error) {
        const errorMessage = error.message || '';

        // Check if error indicates refreshToken expiration
        if (errorMessage.includes('RefreshToken expired or invalid') ||
            errorMessage.includes('400') ||
            this.kiroApiService.refreshTokenFailedAt) {

            console.error('[Kiro Adapter] RefreshToken error detected, emitting expiry event');

            const refreshTokenStatus = this.kiroApiService.isRefreshTokenNearExpiry();
            this._emitRefreshTokenExpiry(refreshTokenStatus);
        }
    }

    /**
     * 广播refreshToken过期事件
     * @private
     * @param {Object} status - refreshToken状态对象
     */
    _emitRefreshTokenExpiry(status) {
        const eventData = {
            uuid: this.config.uuid,
            provider: this.config.MODEL_PROVIDER,
            status: status,
            timestamp: new Date().toISOString(),
            profileArn: this.kiroApiService.profileArn,
            region: this.kiroApiService.region
        };

        console.log(`[Kiro Adapter] Emitting refreshToken expiry event:`, JSON.stringify(eventData, null, 2));
        this.eventEmitter.emit('refreshTokenExpiry', eventData);
    }

    /**
     * 获取refreshToken状态
     * @returns {Object} refreshToken状态信息
     */
    getRefreshTokenStatus() {
        return this.kiroApiService.isRefreshTokenNearExpiry();
    }

    /**
     * 订阅refreshToken过期事件
     * @param {Function} listener - 事件监听器函数
     */
    onRefreshTokenExpiry(listener) {
        this.eventEmitter.on('refreshTokenExpiry', listener);
    }

    /**
     * 取消订阅refreshToken过期事件
     * @param {Function} listener - 事件监听器函数
     */
    offRefreshTokenExpiry(listener) {
        this.eventEmitter.off('refreshTokenExpiry', listener);
    }

    /**
     * Count tokens for a message request (compatible with Anthropic API)
     * @param {Object} requestBody - The request body containing model, messages, system, tools, etc.
     * @returns {Object} { input_tokens: number }
     */
    countTokens(requestBody) {
        return this.kiroApiService.countTokens(requestBody);
    }
}

// Qwen API 服务适配器
export class QwenApiServiceAdapter extends ApiServiceAdapter {
    constructor(config) {
        super();
        this.qwenApiService = new QwenApiService(config);
    }

    async generateContent(model, requestBody) {
        if (!this.qwenApiService.isInitialized) {
            console.warn("qwenApiService not initialized, attempting to re-initialize...");
            await this.qwenApiService.initialize();
        }
        return this.qwenApiService.generateContent(model, requestBody);
    }

    async *generateContentStream(model, requestBody) {
        if (!this.qwenApiService.isInitialized) {
            console.warn("qwenApiService not initialized, attempting to re-initialize...");
            await this.qwenApiService.initialize();
        }
        yield* this.qwenApiService.generateContentStream(model, requestBody);
    }

    async listModels() {
        if (!this.qwenApiService.isInitialized) {
            console.warn("qwenApiService not initialized, attempting to re-initialize...");
            await this.qwenApiService.initialize();
        }
        return this.qwenApiService.listModels();
    }

    async refreshToken() {
        if (this.qwenApiService.isExpiryDateNear()) {
            console.log(`[Qwen] Expiry date is near, refreshing token...`);
            return this.qwenApiService._initializeAuth(true);
        }
        return Promise.resolve();
    }
}

// 用于存储服务适配器单例的映射
export const serviceInstances = {};

// 服务适配器工厂
export function getServiceAdapter(config) {
    console.log(`[Adapter] getServiceAdapter, provider: ${config.MODEL_PROVIDER}, uuid: ${config.uuid}`);
    const provider = config.MODEL_PROVIDER;
    const providerKey = config.uuid ? provider + config.uuid : provider;
    if (!serviceInstances[providerKey]) {
        switch (provider) {
            case MODEL_PROVIDER.OPENAI_CUSTOM:
                serviceInstances[providerKey] = new OpenAIApiServiceAdapter(config);
                break;
            case MODEL_PROVIDER.OPENAI_CUSTOM_RESPONSES:
                serviceInstances[providerKey] = new OpenAIResponsesApiServiceAdapter(config);
                break;
            case MODEL_PROVIDER.GEMINI_CLI:
                serviceInstances[providerKey] = new GeminiApiServiceAdapter(config);
                break;
            case MODEL_PROVIDER.ANTIGRAVITY:
                serviceInstances[providerKey] = new AntigravityApiServiceAdapter(config);
                break;
            case MODEL_PROVIDER.CLAUDE_CUSTOM:
                serviceInstances[providerKey] = new ClaudeApiServiceAdapter(config);
                break;
            case MODEL_PROVIDER.KIRO_API:
                serviceInstances[providerKey] = new KiroApiServiceAdapter(config);
                break;
            case MODEL_PROVIDER.QWEN_API:
                serviceInstances[providerKey] = new QwenApiServiceAdapter(config);
                break;
            default:
                throw new Error(`Unsupported model provider: ${provider}`);
        }
    }
    return serviceInstances[providerKey];
}