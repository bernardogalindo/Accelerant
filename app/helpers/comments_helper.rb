module CommentsHelper

  def show_comment(comment, report = false)
    if comment.hide_until_answered && self.current_user.participant
      @reply_test = Replies.find(:all, :conditions => {:comment_id => comment.id, :user_id => self.current_user.id}, :include => :user)
      if @reply_test.empty?
        suppress = true
      end
    end
    out = "<div class='clientSubComment' id='commentSub#{comment.id}'><a name='##{comment.id}'></a>"
    out = out + "<div class='subCommentAvatar'>"
    out = out + render_avatar(comment.user)
    out = out + "</div>"

    out = out + "<div class='clientSubCommentText' >"
		out = out + "<p>"

		out = out + "<strong><em>"
    out = out + comment.user.name
    out = out + " says:</em></strong><br />"
		#out = out + Remo.new(comment.comment).to_html
    #out = out + comment.comment.gsub(/<\/?[^>]*>/,  "")
    if comment.emailed
      out = out + comment.comment.gsub(/<\/?[^>]*>/,  "")
    else
      out = out + comment.comment
    end
    #out = out + comment.comment
		if comment.photo_content_type
      if comment.photo_content_type =~ /image.*/
        #out = out + "<a href='#{comment.photo.url}' class='MagicThumb' rel='buttons:hide' target='_blank' >"
        out = out + "<a href='#{comment.photo.url}' target='_blank' >"
        #out = out + "<a href='#{comment.photo.url}' rel='zoombox' >"
        out = out + image_tag(comment.photo.url(:thumb), :style => 'margin-left:1px;')
        out = out + "<span>&nbsp;</span>"
        out = out + "</a>"
      else
        out = out + "<p><a href='#{comment.photo.url}' target='_blank'>View attached file here.</a>"
        out = out + image_tag("download.png")
        out = out + "</p>"
      end
		end
		out = out + "<br/>"
		out = out + "<span>- Posted "
    out = out + time_ago_in_words(comment.created_at)
    out = out + " ago </span> <!-- #{comment.created_at}  -->"
    unless report
  		unless @project.lock 
        if !self.current_user.client
          out = out + " | "
          out = out + link_to_remote('Add Comment',
            :url => { :controller => 'plain', :action => 'sub_form', :id => comment.id},
            :complete => "new Effect.SlideDown('subCommentForm#{comment.id}', { duration: .5 })",
            :update => "subCommentForm#{comment.id}")
        end
        if (comment.user.id == self.current_user.id) || self.current_user.admin
  				out = out + " | "
          out = out + link_to_remote("Edit",
            :url => {:controller => 'plain', :action => 'edit_comment', :id => comment.id},
            #:complete => "new Effect.SlideDown('commentSub#{comment.id}', { duration: .2 })",
            :complete => "new Effect.Parallel([new Effect.SlideDown('commentSub#{comment.id}', { duration: .2 }),
            new Effect.SlideUp('responder_form', { duration: .2 })
            ],{duration: 0.8,delay: 0.5})",
            :update => "commentSub#{comment.id}")
        end
        if (comment.user.id == self.current_user.id) || self.current_user.admin  || self.current_user.moderator
  				out = out + " | "
          out = out + link_to_remote("Delete",
            :confirm => "Are you sure you want to delete this?",
            :url => {:controller => 'plain', :action => 'drop_comment', :id => comment.id},
            :complete => "new Effect.Fade('commentSub#{comment.id}', { duration: 2 })",
            :update => "commentSub#{comment.id}")
        end

        if (self.current_user.admin || self.current_user.moderator)
          if comment.for_report == 1
            flag = true
          else
            flag = false
          end
  				out = out + " | Add to Report "
          out = out + check_box_tag("comment_#{comment.id}",comment.id, flag, 
        :onclick => remote_function(
        :update => "comment_#{comment.id}", 
        :url => {:controller => "comments", :action => :update_report_flag }, 
        :with => "'id='+$('comment_#{comment.id}').value", 
        :complete => "new Effect.SlideDown('subCommentForm#{comment.id}', { duration: .5 })" ))
        end
		
		if self.current_user.admin  || self.current_user.moderator
				out = out + " | "
        out = out + link_to("Reorder",
          :controller => 'comments', :action => 'sort', :id => comment.discussion_id)
        end
      end
    end
		out = out + "<div id='subCommentForm#{comment.id}' class='replyStyle' style='display:none;'></div>"
		out = out + "<div id='reclaimer#{comment.id}'></div>"
    if suppress
      @replies = Replies.find(:all, :conditions => "1 = 2")
    else
      @replies = Replies.find(:all, :conditions => { :comment_id => comment.id}, :order => "id ASC", :include => :user)
    end
    for replies in @replies
      displayflag = true
      if cookies[:filter] == "yes"
        displayflag = false
        cookies.to_hash.each_pair do |k, v|
          if cookies[k.to_sym].split('_')[0] == "field"
            #puts "start"
            #puts cookies[k.to_sym]  #e.g. "field_10"
            #puts k                  #e.g. "male"
            #puts "stop"
            #if replies.user.send(cookies[k.to_sym]) == k  #e.g. if user.field_10 == "male"
              #displayflag = true
            #end
            testuser = User.find_by_id(replies.user.id,:conditions => cookies[:sql])
            if testuser.nil?
              if !User.is_participant.find_by_id(replies.user.id)
                displayflag = true
              else
                displayflag = false
              end
              #puts "no match"
            else
              displayflag = true
              #puts "match"
            end
          end
        end
      end
      #displayflag = filter_results(replies)
      if displayflag && User.exists?(replies.user_id)
        if !@project.one_to_one || ((replies.user.id == self.current_user.id || replies.user.admin? || replies.user.moderator?) || self.current_user.admin? || self.current_user.moderator? || self.current_user.client? )
          out = out + render_reply(replies)
        end
      end
		end
		out = out + "<div id='#{dom_id(comment)}'>"
		out = out + "</div>"
    out = out + "<a name='subCommentForm#{comment.id}' ></a>"
    #out = out + "<div id='subCommentForm#{comment.id}' class='replyStyle' style='display:none;'></div>"
		out = out + "</div>"
		out = out + "<hr noshade='noshade'/>"
    out = out + "</div>"
    return out
  end

  def show_comment_lite(comment)
    #not currently being used
    out = "<div class='clientSubComment' id='commentSub#{comment.id}'><a name='##{comment.id}'></a>"
    out = out + "<div class='subCommentAvatar'>"
    out = out + render_avatar(comment.user)
    out = out + "</div>"

    out = out + "<div class='clientSubCommentText' >"
		out = out + "<p>"

		out = out + "<strong>"
    out = out + comment.user.name
    out = out + "</strong> "
		out = out + comment.comment
		if comment.photo_content_type
      if comment.photo_content_type =~ /image.*/
        #out = out + "<a href='#{comment.photo.url}' class='MagicThumb' rel='buttons:hide' target='_blank' >"
        out = out + "<a href='#{comment.photo.url}' target='_blank' >"
        out = out + image_tag(comment.photo.url(:thumb), :style => 'margin-left:1px;')
        out = out + "<span>&nbsp;</span>"
        out = out + "</a>"
      else
        out = out + "<p><a href='#{comment.photo.url}' target='_blank'>View attached file here.</a>"
        out = out + image_tag("download.png")
        out = out + "</p>"
      end
		end
		out = out + "<br/>"

		out = out + "<span>- Posted "
    out = out + time_ago_in_words(comment.created_at)
    out = out + " ago </span>"
		

		out = out + "<div id='subCommentForm#{comment.id}'></div>"
		out = out + "<div id='reclaimer#{comment.id}'></div>"
		@replies = Replies.find(:all, :conditions => { :comment_id => comment.id}, :order => "id DESC", :include => :user)
		for replies in @replies
      displayflag = true
      if cookies[:filter] == "yes"
        displayflag = false
        cookies.to_hash.each_pair do |k, v|
          if cookies[k.to_sym].split('_')[0] == "field"
            #puts cookies[k.to_sym]
            #puts k
            if replies.user.send(cookies[k.to_sym]) == k
              displayflag = true
            end
          end
        end
      end

      if displayflag
        out = out + render_reply(replies)
      end
		end
		out = out + "<div id='#{dom_id(comment)}'>"
		out = out + "</div>"
		out = out + "</div>"
		out = out + "<hr noshade='noshade'/>"
    out = out + "</div>"
    return out
  end

end
