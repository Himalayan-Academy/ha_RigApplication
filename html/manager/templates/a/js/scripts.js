/*
 * jQuery Selectbox plugin 0.1.3
 *
 * Copyright 2011, Dimitar Ivanov (http://www.bulgaria-web-developers.com/projects/javascript/selectbox/)
 * Licensed under the MIT (http://www.opensource.org/licenses/mit-license.php) license.
 * 
 * Date: Wed Jul 29 23:20:57 2011 +0200
 */
(function($,undefined){var PROP_NAME="selectbox",FALSE=false,TRUE=true;function Selectbox(){this._state=[];this._defaults={classHolder:"sbHolder",classHolderDisabled:"sbHolderDisabled",classSelector:"sbSelector",classOptions:"sbOptions",classGroup:"sbGroup",classSub:"sbSub",classDisabled:"sbDisabled",classToggleOpen:"sbToggleOpen",classToggle:"sbToggle",speed:200,effect:"slide",onChange:null,onOpen:null,onClose:null}}$.extend(Selectbox.prototype,{_isOpenSelectbox:function(target){if(!target){return FALSE}var inst=this._getInst(target);return inst.isOpen},_isDisabledSelectbox:function(target){if(!target){return FALSE}var inst=this._getInst(target);return inst.isDisabled},_attachSelectbox:function(target,settings){if(this._getInst(target)){return FALSE}var $target=$(target),self=this,inst=self._newInst($target),sbHolder,sbSelector,sbToggle,sbOptions,s=FALSE,optGroup=$target.find("optgroup"),opts=$target.find("option"),olen=opts.length;$target.attr("sb",inst.uid);$.extend(inst.settings,self._defaults,settings);self._state[inst.uid]=FALSE;$target.hide();function closeOthers(){var key,uid=this.attr("id").split("_")[1];for(key in self._state){if(key!==uid){if(self._state.hasOwnProperty(key)){if($(":input[sb='"+key+"']")[0]){self._closeSelectbox($(":input[sb='"+key+"']")[0])}}}}}sbHolder=$("<div>",{id:"sbHolder_"+inst.uid,"class":inst.settings.classHolder});sbSelector=$("<a>",{id:"sbSelector_"+inst.uid,href:"#","class":inst.settings.classSelector,click:function(e){e.preventDefault();closeOthers.apply($(this),[]);var uid=$(this).attr("id").split("_")[1];if(self._state[uid]){self._closeSelectbox(target)}else{self._openSelectbox(target)}}});sbToggle=$("<a>",{id:"sbToggle_"+inst.uid,href:"#","class":inst.settings.classToggle,click:function(e){e.preventDefault();closeOthers.apply($(this),[]);var uid=$(this).attr("id").split("_")[1];if(self._state[uid]){self._closeSelectbox(target)}else{self._openSelectbox(target)}}});sbToggle.appendTo(sbHolder);sbOptions=$("<ul>",{id:"sbOptions_"+inst.uid,"class":inst.settings.classOptions,css:{display:"none"}});$target.children().each(function(i){var that=$(this),li,config={};if(that.is("option")){getOptions(that)}else{if(that.is("optgroup")){li=$("<li>");$("<span>",{text:that.attr("label")}).addClass(inst.settings.classGroup).appendTo(li);li.appendTo(sbOptions);if(that.is(":disabled")){config.disabled=true}config.sub=true;getOptions(that.find("option"),config)}}});function getOptions(){var sub=arguments[1]&&arguments[1].sub?true:false,disabled=arguments[1]&&arguments[1].disabled?true:false;arguments[0].each(function(i){var that=$(this),li=$("<li>"),child;if(that.is(":selected")){sbSelector.text(that.text());s=TRUE}if(i===olen-1){li.addClass("last")}if(!that.is(":disabled")&&!disabled){child=$("<a>",{href:"#"+that.val(),rel:that.val(),text:that.text(),click:function(e){e.preventDefault();var t=sbToggle,uid=t.attr("id").split("_")[1];self._changeSelectbox(target,$(this).attr("rel"),$(this).text());self._closeSelectbox(target)}});if(sub){child.addClass(inst.settings.classSub)}child.appendTo(li)}else{child=$("<span>",{text:that.text()}).addClass(inst.settings.classDisabled);if(sub){child.addClass(inst.settings.classSub)}child.appendTo(li)}li.appendTo(sbOptions)})}if(!s){sbSelector.text(opts.first().text())}$.data(target,PROP_NAME,inst);sbSelector.appendTo(sbHolder);sbOptions.appendTo(sbHolder);sbHolder.insertAfter($target)},_detachSelectbox:function(target){var inst=this._getInst(target);if(!inst){return FALSE}$("#sbHolder_"+inst.uid).remove();$.data(target,PROP_NAME,null);$(target).show()},_changeSelectbox:function(target,value,text){var inst=this._getInst(target),onChange=this._get(inst,"onChange");$("#sbSelector_"+inst.uid).text(text);$(target).find("option[value='"+value+"']").attr("selected",TRUE);if(onChange){onChange.apply((inst.input?inst.input[0]:null),[value,inst])}else{if(inst.input){inst.input.trigger("change")}}},_enableSelectbox:function(target){var inst=this._getInst(target);if(!inst||!inst.isDisabled){return FALSE}$("#sbHolder_"+inst.uid).removeClass(inst.settings.classHolderDisabled);inst.isDisabled=FALSE;$.data(target,PROP_NAME,inst)},_disableSelectbox:function(target){var inst=this._getInst(target);if(!inst||inst.isDisabled){return FALSE}$("#sbHolder_"+inst.uid).addClass(inst.settings.classHolderDisabled);inst.isDisabled=TRUE;$.data(target,PROP_NAME,inst)},_optionSelectbox:function(target,name,value){var inst=this._getInst(target);if(!inst){return FALSE}inst[name]=value;$.data(target,PROP_NAME,inst)},_openSelectbox:function(target){var inst=this._getInst(target);if(!inst||inst.isOpen||inst.isDisabled){return }var el=$("#sbOptions_"+inst.uid),viewportHeight=parseInt($(window).height(),10),offset=$("#sbHolder_"+inst.uid).offset(),scrollTop=$(window).scrollTop(),height=el.prev().height(),diff=viewportHeight-(offset.top-scrollTop)-height/2,onOpen=this._get(inst,"onOpen");el.css({top:height+"px",maxHeight:(diff-height)+"px"});inst.settings.effect==="fade"?el.fadeIn(inst.settings.speed):el.slideDown(inst.settings.speed);$("#sbToggle_"+inst.uid).addClass(inst.settings.classToggleOpen);this._state[inst.uid]=TRUE;inst.isOpen=TRUE;if(onOpen){onOpen.apply((inst.input?inst.input[0]:null),[inst])}$.data(target,PROP_NAME,inst)},_closeSelectbox:function(target){var inst=this._getInst(target);if(!inst||!inst.isOpen){return }var onClose=this._get(inst,"onClose");inst.settings.effect==="fade"?$("#sbOptions_"+inst.uid).fadeOut(inst.settings.speed):$("#sbOptions_"+inst.uid).slideUp(inst.settings.speed);$("#sbToggle_"+inst.uid).removeClass(inst.settings.classToggleOpen);this._state[inst.uid]=FALSE;inst.isOpen=FALSE;if(onClose){onClose.apply((inst.input?inst.input[0]:null),[inst])}$.data(target,PROP_NAME,inst)},_newInst:function(target){var id=target[0].id.replace(/([^A-Za-z0-9_-])/g,"\\\\$1");return{id:id,input:target,uid:Math.floor(Math.random()*99999999),isOpen:FALSE,isDisabled:FALSE,settings:{}}},_getInst:function(target){try{return $.data(target,PROP_NAME)}catch(err){throw"Missing instance data for this selectbox"}},_get:function(inst,name){return inst.settings[name]!==undefined?inst.settings[name]:this._defaults[name]}});$.fn.selectbox=function(options){var otherArgs=Array.prototype.slice.call(arguments,1);if(typeof options=="string"&&options=="isDisabled"){return $.selectbox["_"+options+"Selectbox"].apply($.selectbox,[this[0]].concat(otherArgs))}if(options=="option"&&arguments.length==2&&typeof arguments[1]=="string"){return $.selectbox["_"+options+"Selectbox"].apply($.selectbox,[this[0]].concat(otherArgs))}return this.each(function(){typeof options=="string"?$.selectbox["_"+options+"Selectbox"].apply($.selectbox,[this].concat(otherArgs)):$.selectbox._attachSelectbox(this,options)})};$.selectbox=new Selectbox();$.selectbox.version="0.1.3"})(jQuery);

$(document).ready(function() { /* run the following code when the DOM is ready */
	
	$(function () { /* initiate custom select boxes */
		$('select').selectbox({effect: 'fade'});
	});
	$('.page-content, .footer-info').delegate('.sbOptions a', 'click', function() { /* adds a custom class once an option is selected, for styling purposes */
		$(this).parent().parent().parent().addClass('selected');
	});
	
	$('.footer-info').delegate('.sbToggle, .sbSelector', 'click', function() { /* adjusts height of option box depending on how many items it contains */
		current_height = (28 * ( ( $('.footer-info .sbOptions li').length) -1 ) ) * -1;
		$('.footer-info .sbOptions').css({top: current_height});
	});
	
	$('.page-footer .footer-content').hide(); /* hide footer regions on page load */
	$('.footer-info').delegate('.sbOptions a', 'click', function() { /* expands/collapses footer content regions based on the index of the option selected */
		footer_to_toggle = ':eq(' + ($(this).parent().index() - 1) + ')';
		$('.page-footer .footer-regions').children(footer_to_toggle).siblings().slideUp('fast');
		$('.page-footer .footer-regions').children(footer_to_toggle).slideDown('fast');
		$('html,body').animate({scrollTop: $('.page-footer .footer-regions').children(footer_to_toggle).offset().top},'fast');
	});
	
	$(function() { /* prime custom radio buttons */
		$( ".radio" ).buttonset();
	});
	
	$(function() { /* prime custom checkboxes */
		$( ".checkbox" ).buttonset();
	});
	
	var form_value = [];
	$(':text').each(function(i) { /* automatically clear text input values on click/focus and reset on unfocus if left empty */
		i++;
		form_value[i] = this.value;
		
		$(this).focus(function(){
			if (this.value == form_value[i]) {
				this.value = '';
			}
		});
		
		$(this).blur(function(){
			if (this.value == '') {
				this.value = form_value[i];
			}
		});
	});
	
		
	$('.hero .hero-slides').cycle({ /* home page hero slideshow */
		fx: 'scrollHorz', /* animation effect */
		prev: '.page-header .slideshow .arrow-prev a', /* button to use to advance slide */
		next: '.page-header .slideshow .arrow-next a', /* button to use to reverse slide */
		timeout: 8000 /* time, in milliseconds, to wait between slides automatically transition */
	});
	
	$('.page-header .slideshow .arrow-prev a, .page-header .slideshow .arrow-next a').click(function(event) { /* forces the home page hero slideshow to pause if anyone clicks the next or previous slide links */
		$('.hero .hero-slides').cycle('pause');
		event.preventDefault();
	});
	
    $('.page-content .slides').cycle({ /* basic slideshows */
		fx: 'scrollHorz',
		prev: '.page-content .slideshow .arrow-prev a',
		next: '.page-content .slideshow .arrow-next a, .slide img',
		pager: '.page-content .slideshow .slidecontrol-select', /* select what container to use to populate with clickable dots that indicate currently viewed slide or page */
		timeout: 0
	});
	
	/* paginated content */
	$(function() { /* loop through every paginate container on the page to paginate them individually */
    	$('.paginate').each(function() {
    		parent_width = $(this).children().innerWidth() + 40;
	    	current_pager = $(this).parent();
	        $(this).cycle({
	            fx:     'scrollHorz',
	            prev: $(' .arrow-prev a', current_pager),
				next: $(' .arrow-next a', current_pager),
				pager: $(this).parent().children('.slidecontrol-select'),
				timeout: 0,
				fit: 1,
				width: parent_width
	        });
        });
    });
    
    $(function() { /* some sections have titles that won't paginate with the content and have to be marked up differently, so let's loop through those */
    	$('.paginate-has-title').each(function() {
    		parent_width = $(this).children().innerWidth() + 40;
	    	current_pager = $(this).parent().parent();
	        $(this).cycle({
	            fx:     'scrollHorz',
	            prev: $(' .arrow-prev a', current_pager),
				next: $(' .arrow-next a', current_pager),
				pager: $(this).parent().parent().children('.slidecontrol-select'),
				timeout: 0,
				fit: 1,
				width: parent_width
	        });
        });
    });
	
	/* pulldown menu in header */
	$('.pulldown-content').hide(); /* hide on page load */
	$('.page-header .inner-wrapper').prepend('<a class="pulldown-tab" href="#">Expand Our Network Menu</a>'); /* attach pulldown tab here since it's useless without .js */
	$('.pulldown-content').append('<a class="pulldown-close" title="Close this menu" href="#">X</a>'); /* attach pulldown close link here since it's useless without .js */
	$('.page-header, .pulldown-content').delegate('.pulldown-tab, .pulldown-close', 'click', function(event) {
		$('.pulldown-content').slideToggle('fast');
		if ($('.home .page-header .logo').css('top') == '0px') {
			$('.home .page-header .logo').animate({top: '-46px'}, 'fast'); /* due to location in markup, the logo must be animated to move with the menu's expansion */
		} else {
			$('.home .page-header .logo').animate({top: '0'}, 'fast');
		}
		event.preventDefault();
	});
	
	
	/* tabbed content areas */	
	$('.tabs, .picks-nav').each(function() { /* dynamically add classes for showing/hiding */
		$(this).children(':first').addClass('active');
	});
	
	$('.tabulate').each(function() {
		$(this).children(':gt(0)').addClass('hide');
	});
	
	/* toggles tabs and content based off previously-assigned class names */
	$('.tabs').delegate('a', 'click', function(event) {
		tab_to_toggle = ':eq(' + $(this).parent().index() + ')';
		$(this).parent().parent().parent().children('.tabulate').children().siblings().addClass('hide');
		$(this).parent().parent().parent().children('.tabulate').children(tab_to_toggle).removeClass('hide');
		$(this).parent().siblings().removeClass('active');
		$(this).parent().addClass('active');
		event.preventDefault();
	});
	
	/* custom tab code for picks area due to custom scrollbars adding markup */
	$('.picks-nav').delegate('a', 'click', function(event) {
		tab_to_toggle = ':eq(' + $(this).parent().index() + ')';
		$(this).parent().parent().parent().parent().children('.tabulate').children().siblings().addClass('hide');
		$(this).parent().parent().parent().parent().children('.tabulate').children(tab_to_toggle).removeClass('hide');
		$(this).parent().siblings().removeClass('active');
		$(this).parent().addClass('active');
		event.preventDefault();
	});
	
	/* initiate custom scrollbars */
	$('.scrollbar').scrollbar();
	
	/* initiate hover state markup for monocle book here... makes no sense without javascript active */
	$('.monocle-detail').append('<div class="monocle-hover"> <h4 class="h4">You can view this book on this page</h4> <a class="action-bg" href="../gurudevas-spiritual-visions/book-detail-page.html">Read Book Now</a> <p>Swipe pages from left to right</p></div>');
	
	/* load monocle content via ajax */
	clicked = 'false';
	$('.media-detail').delegate('.monocle', 'click', function(event) {
		$('.monocle').css({'position' : 'absolute' });
		$('.monocle-detail, .caption .monocle').hide();
		$.ajax({
		  url: $(this).attr('href'),
		  success: function(data) {
		  	if ( clicked == 'false' ) {
			  	$('.featured-item .media-detail').prepend('<iframe class="monocle-content"></iframe>');
			    $('.monocle-content').html(data);
			    clicked = 'true';
		  	}
		  }
		});
		event.preventDefault();
	});
	
	$('.monocle-fancybox').fancybox({ /* lightbox for the full-screen monocle plugin */
		'height'			: '100%',
		'type'				: 'iframe'
	});
	
	/* changes the behavior of share buttons from hover to click when javascript is active */
	$('.content-article .share-options').children('.social').hide(); /* hide the share hover menu on page load */
	$('.content-article .share-options').children().removeClass('nojs'); /* remove no js class to override default hover behavior */
	$('.content-article .share-options .social').prepend('<a class="close" href="#">X</a>'); /* add a close link */
	$('.share-options').delegate('.open-menu', 'click', function(event) {
		$(this).parent().addClass('open');
		$(this).parent().children('.social').fadeIn('fast');
		event.preventDefault();
	});
	
	$('.content-article').delegate('.close', 'click', function(event) { /* close menu */
		$(this).parent().parent().removeClass('open');
		$(this).parent().fadeOut('fast');
		event.preventDefault();
	});
});