# coding: utf-8

# 默认配置项
# 如需新增设置项，请在这里初始化默认值，然后到后台修改
# 首页
# SiteConfig.index_html
SiteConfig.save_default("index_html",<<-eos
<div class="box" style="text-align:center;">
  <p><img alt="Big_logo" src="/assets/big_logo.png"></p>
  <p></p>
  <p>MakeSlide Group， 致力于构建完善的 Ruby 中文社区。</p>
  <p>功能正在完善中，欢迎 <a href="http://github.com/huacnlee/ruby-china">贡献代码</a> 。</p>
  <p>诚邀有激情的活跃 Ruby 爱好者参与维护社区，联系 <b style="color:#c00;">lgn21st@gmail.com</b></p>
</div>
eos
)


# Footer HTML
SiteConfig.save_default("footer_html",<<-eos
<p class="copyright">
 &copy; MakeSlide Group.
</p>
eos
)

# 话题后面的HTML代码
SiteConfig.save_default("after_slide_html",<<-eos
<div class="share_links">
 <a href="https://twitter.com/share" class="twitter-share-button" data-count="none"">Tweet</a>
 <script type="text/javascript" src="//platform.twitter.com/widgets.js"></script>
</div>
eos
)

# 话题正文前面的HTML
SiteConfig.save_default("before_slide_html",<<-eos
eos
)


# 自定有 HTML head 区域的内容
SiteConfig.save_default("custom_head_html",<<-eos
<link rel="dns-prefetch" href="//assets.youhost.com">
eos
)

# 禁止回复的某些词语
SiteConfig.save_default("ban_words_on_reply","mark\n收藏\n顶\n赞\nup\n")

# 开放注册
SiteConfig.save_default("allow_register","true")




