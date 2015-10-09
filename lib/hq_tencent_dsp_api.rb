require "hq_tencent_dsp_api/version"
require 'net/http'
module HqTencentDspApi
	DSP_ID = '190'
	TOKEN = '73553e669b7270a4934706f76a99ad36'
	AD_LIST_URL = 'http://opentest.adx.qq.com/location/list' #广告位信息同步API
	UPLOAD_ORDER_URl = 'http://opentest.adx.qq.com/order/sync' #广告信息同步API
	DENY_STATUS_URL = 'http://opentest.adx.qq.com/file/denylist' #获取审核未通过的广告信息API
	GET_STARTUS_URL = 'http://opentest.adx.qq.com/order/getstatus' #批量获取广告的审核状态
	UPLOAD_CUSTOMER_INFO_URL = 'http://opentest.adx.qq.com/client/sync' #批量上传客户信息审核
	GET_CUSTOMER_STATUS_URL= 'http://opentest.adx.qq.com/client/info' #批量获取客户的审核信息
	GET_QUALITIFIED_URL = 'http://opentest.adx.qq.com/client/quali'	#获取审核通过客户的信息
	REPORT_FORM_URL = 'http://opentest.adx.qq.com/order/report'#获取腾讯一个时间段内的数据报表
  # Your code goes here...
  	def self.upload_order_info(order_info)
		url = UPLOAD_ORDER_URl
		params = {
			'dsp_id' => DSP_ID,
			'token' => TOKEN,
		}
		order_info = {"order_info"=>order_info}
		url = URI.parse(url)
		parameters = params.merge(order_info)
		result = Net::HTTP.post_form(url,parameters)
		return result
	end


	#广告位信息同步------------下载广告位信息
	def self.load_ad_from_adx(date=nil)
		url = AD_LIST_URL
		params = {
			"dsp_id" => DSP_ID,
			"token"=>TOKEN,
			"date"=> (date.nil? ? '' : date)
		}
		result = post(url,params)
		return result
	end

	#获取审核未通过的广告信息
	def self.get_ads_info_of_deny(upload_date)
		url = DENY_STATUS_URL
		params = {
			"dsp_id"=>DSP_ID,
			"token"=>TOKEN,
			"upload_date"=>upload_date
		}
		result = post(url,params)
		return result
	end

	#批量获取广告的审核状态
	# result = TencentAdList.new.nums_of_ad_status(["48"].to_json)
	# {"ret_code"=>0, "ret_msg"=>{"total"=>1, "count"=>1, "records"=>{"48"=>[{"status"=>"待审核", "client_name"=>"浩趣互动", "file_count"=>"1", 
	# 	"file_info"=>["http://dsp.hogic.cn/Public/Uploads/201508/55e00f321ba3c.flv#48"], "targeting_url"=>"http://dsp.hogic.cn", "monitor_url"=>"[]", "monitor_position"=>[""]}]}}, "error_code"=>0}
	def self.nums_of_ad_status(dsp_order_id_info)
		url = GET_STARTUS_URL
		# url = URI.parse(url)
		params = {
			"dsp_id"=>DSP_ID,
			"token"=>TOKEN,
			"dsp_order_id_info"=>dsp_order_id_info
		}
		result = post(url,params)
		return result
	end

	def post(url,params)
		url = URI(url)
		# http = Net::HTTP.new(url.host,url.port)
		# request = Net::HTTP::Post.new(http.request_uri)
		# request.body = params.to_json
		# response = http.request(request)
		# result = response.body
		result = Net::HTTP.post_form(url,params)
		result = ActiveSupport::JSON.decode(result.body)
		if result["ret_code"].to_i!=0
			raise "请求错误：#{result}"
		end
		return result
	end


	#客户信息同步----------批量上传客户信息
	def self.upload_customer_info_confirm(client_info)
		url = UPLOAD_CUSTOMER_INFO_URL
		params = {
			"dsp_id"=>DSP_ID,
			"token"=>TOKEN,
			"client_info"=>client_info||[]
		}
		result = post(url,params)
		return result
	end

	#批量获取客户审核信息
	# names = [{'names':'浩趣互动'}.to_json]
	# result = TencentAdList.new.get_customer_status(names)
	 # => {"ret_code"=>0, "ret_msg"=>{"浩趣互动"=>{"verify_status"=>"待通过", "audit_info"=>"", "is_black"=>"N", "type"=>"ADX", "vocation"=>"", "vocation_all"=>""}}, "error_code"=>0}
	def self.get_customer_status(names)
		url =  GET_CUSTOMER_STATUS_URL
		params={
			"dsp_id"=>DSP_ID,
			"token"=>TOKEN,
			"names"=>names||[]
		}
		p params
		result = post(url,params)
		return result
	end

	#获取审核通过客户的信息
	def self.get_customer_qualitied
		url = GET_QUALITIFIED_URL
		params = {
			"dsp_id"=>DSP_ID,
			"token"=>TOKEN,
		}
		result = post(url,params)
		return result
	end

	#腾讯报表  --用于定时任务调取
	def self.get_tencent_report_form(start_date,end_date)
		url = REPORT_FORM_URL
		#由于start_date 跟end_date之间的差值超过7腾讯会直接报错，所以这地方判断一下，超过7就直接退出不去请求
		s= Date.parse(start_date)-Date.parse(end_date)
		if !s.nil? && s.to_i>7
			raise '请求下载报表数据不能超过一周'
		end
		params = {
			"dsp_id"=>DSP_ID,
			"token"=>TOKEN,
			"start_date"=>start_date,
			"end_date"=>end_date
		}
		result = post(url,params)
		if result["ret_code"].to_i != 0
			raise "请求错误 #{result}"
		end
		return result
	end

	#添加一个地址
	def getTrackingUrl(hqAdId,hqCreativeId,hqSource='youku',hqEvent=1)
	    sql = "select *,hq_expand_ad.id as aid from hq_expand_ad left join hq_expand_plan on hq_expand_ad.plan=hq_expand_plan.id where hq_expand_ad.id=#{hqAdId}"
		conn = ActiveRecord::Base.connection_pool.checkout
		results = conn.select_all(sql).to_hash
	    result = results[0]
	    hqClientId = result['company']
	    hqAdId = result['aid']
	    hqGroupId = result['plan']
	    # $hqCreativeId = $result['originality'];
	     return "http://track.hogic.cn/api/ads?hqClientId=#{hqClientId}&hqGroupId=#{hqGroupId}&hqAdId=#{hqAdId}&hqCreativeId=#{hqCreativeId}&hqSource=#{hqSource}&hqEvent=#{hqEvent}"
	end
end
