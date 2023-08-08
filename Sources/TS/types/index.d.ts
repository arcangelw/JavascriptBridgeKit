/// <reference path="global.d.ts" />

declare namespace JS {

	/**
	 * 回调消息类型
	 */
	const enum MessageType {
		/** 
		 * 回调消息
		 */
		Callback = 'callback',
		/**
		 * 事件消息
		 */
		Event = 'event'
	}

	/**
	 * 发送消息体
	 */
	interface SendMessage {
		/** 
		 * 模块 
		 */
		module: string,
		/**
		 * 方法
		 */
		method: string,
		/**
		 * 数据
		 */
		data: any[]
	}

	/**
	 * 发送消息体中回调id
	 */
	interface SendMessageCallbackId {
		/**
		 * 回调id
		 */
		callbackId: string
	}

	/**
	 * 回调消息体
	 */
	interface CallbackMessage {
		/**
		 * 回调消息类型
		 */
		messageType: MessageType,
		/**
		 * 回调方法id
		 */
		callbackId?: string,
		/**
		 * 回调事件名称
		 */
		eventName?: string,
		/**
		 * 回调数据
		 */
		data: any[]
	}

	/**
	 * 同步返回数据结构
	 */
	interface SyncResult {
		/**
		 * 反回数据
		 */
		value?: any;
	}

	/**
	 * 回调函数
	 */
	type Callback = Function;

	/**
	 * 事件回调函数
	 */
	type EventCallback = Callback;
}