// jquery.dynatree.js build 0.4.2
// Revision: 216, date: 2009-04-19 08:08:47
// Copyright (c) 2008-09  Martin Wendt (http://dynatree.googlecode.com/)
// Licensed under the MIT License.

var _canLog=true;function _log(mode,msg){if(!_canLog)
return;var args=Array.prototype.slice.apply(arguments,[1]);var dt=new Date();var tag=dt.getHours()+":"+dt.getMinutes()+":"+dt.getSeconds()+"."+dt.getMilliseconds();args[0]=tag+" - "+args[0];try{switch(mode){case"info":window.console.info.apply(window.console,args);break;case"warn":window.console.warn.apply(window.console,args);break;default:window.console.log.apply(window.console,args);}}catch(e){if(!window.console)
_canLog=false;}}
function logMsg(msg){Array.prototype.unshift.apply(arguments,["debug"]);_log.apply(this,arguments);}
var DTNodeStatus_Error=-1;var DTNodeStatus_Loading=1;var DTNodeStatus_Ok=0;;(function($){var Class={create:function(){return function(){this.initialize.apply(this,arguments);}}}
var DynaTreeNode=Class.create();DynaTreeNode.prototype={initialize:function(parent,tree,data){this.parent=parent;this.tree=tree;if(typeof data=="string")
data={title:data};if(data.key==undefined)
data.key="_"+tree._nodeCount++;this.data=$.extend({},$.ui.dynatree.nodedatadefaults,data);this.div=null;this.span=null;this.childList=null;this.isRead=false;this.hasSubSel=false;if(tree.initMode=="cookie"){if(tree.initActiveKey==this.data.key)
tree.activeNode=this;if(tree.initFocusKey==this.data.key)
tree.focusNode=this;this.bExpanded=($.inArray(this.data.key,tree.initExpandedKeys)>=0);this.bSelected=($.inArray(this.data.key,tree.initSelectedKeys)>=0);}else{if(data.activate)
tree.activeNode=this;if(data.focus)
tree.focusNode=this;this.bExpanded=(data.expand==true);this.bSelected=(data.select==true);}
if(this.bExpanded)
tree.expandedNodes.push(this);if(this.bSelected)
tree.selectedNodes.push(this);},toString:function(){return"dtnode<"+this.data.key+">: '"+this.data.title+"'";},toDict:function(recursive,callback){var dict=$.extend({},this.data);dict.activate=(this.tree.activeNode===this);dict.focus=(this.tree.focusNode===this);dict.expand=this.bExpanded;dict.select=this.bSelected;if(callback)
callback(dict);if(recursive&&this.childList){dict.children=[];for(var i=0;i<this.childList.length;i++)
dict.children.push(this.childList[i].toDict(true,callback));}else{delete dict.children;}
return dict;},_getInnerHtml:function(){var opts=this.tree.options;var cache=this.tree.cache;var rootParent=opts.rootVisible?null:this.tree.tnRoot;var bHideFirstExpander=(opts.rootVisible&&opts.minExpandLevel>0)||opts.minExpandLevel>1;var bHideFirstConnector=opts.rootVisible||opts.minExpandLevel>0;var res="";var p=this.parent;while(p){if(bHideFirstConnector&&(p==rootParent))
break;res=(p.isLastSibling()?cache.tagEmpty:cache.tagVline)+res;p=p.parent;}
if(bHideFirstExpander&&this.parent==rootParent){}else if(this.childList||this.data.isLazy){res+=cache.tagExpander;}else{res+=cache.tagConnector;}
if(opts.checkbox&&this.data.hideCheckbox!=true&&!this.data.isStatusNode){res+=cache.tagCheckbox;}
if(this.data.icon){res+="<img src='"+opts.imagePath+this.data.icon+"' alt='' />";}else if(this.data.icon==false){}else{res+=cache.tagNodeIcon;}
var tooltip=(this.data&&typeof this.data.tooltip=="string")?" title='"+this.data.tooltip+"'":"";res+="<a href='#'"+tooltip+">"+this.data.title+"</a>";return res;},render:function(bDeep,bHidden){if(!this.div){this.span=document.createElement("span");this.span.dtnode=this;if(this.data.key)
this.span.id=this.tree.options.idPrefix+this.data.key;this.div=document.createElement("div");this.div.appendChild(this.span);if(this.parent)
this.parent.div.appendChild(this.div);if(this.parent==null&&!this.tree.options.rootVisible)
this.span.style.display="none";}
this.span.innerHTML=this._getInnerHtml();this.div.style.display=(this.parent==null||this.parent.bExpanded?"":"none");var opts=this.tree.options;var cn=opts.classNames;var isLastSib=this.isLastSibling();var cnList=[];cnList.push((this.data.isFolder)?cn.folder:cn.document);if(this.bExpanded)
cnList.push(cn.expanded);if(this.data.isLazy&&!this.isRead)
cnList.push(cn.lazy);if(isLastSib)
cnList.push(cn.lastsib);if(this.bSelected)
cnList.push(cn.selected);if(this.hasSubSel)
cnList.push(cn.partsel);if(this.tree.activeNode===this)
cnList.push(cn.active);if(this.data.addClass)
cnList.push(this.data.addClass);cnList.push(cn.combinedExpanderPrefix
+(this.bExpanded?"e":"c")
+(this.data.isLazy&&!this.isRead?"d":"")
+(isLastSib?"l":""));cnList.push(cn.combinedIconPrefix
+(this.bExpanded?"e":"c")
+(this.data.isFolder?"f":""));this.span.className=cnList.join(" ");if(bDeep&&this.childList&&(bHidden||this.bExpanded)){for(var i=0;i<this.childList.length;i++){this.childList[i].render(bDeep,bHidden)}}},hasChildren:function(){return this.childList!=null;},isLastSibling:function(){var p=this.parent;if(!p)return true;return p.childList[p.childList.length-1]===this;},prevSibling:function(){if(!this.parent)return null;var ac=this.parent.childList;for(var i=1;i<ac.length;i++)
if(ac[i]===this)
return ac[i-1];return null;},nextSibling:function(){if(!this.parent)return null;var ac=this.parent.childList;for(var i=0;i<ac.length-1;i++)
if(ac[i]===this)
return ac[i+1];return null;},_setStatusNode:function(data){var firstChild=(this.childList?this.childList[0]:null);if(!data){if(firstChild){this.div.removeChild(firstChild.div);if(this.childList.length==1)
this.childList=null;else
this.childList.shift();}}else if(firstChild){data.isStatusNode=true;firstChild.data=data;firstChild.render(false,false);}else{data.isStatusNode=true;firstChild=this._addNode(data);}},setLazyNodeStatus:function(lts){switch(lts){case DTNodeStatus_Ok:this._setStatusNode(null);this.isRead=true;this.render(false,false);if(this.tree.options.autoFocus){if(this===this.tree.tnRoot&&!this.tree.options.rootVisible&&this.childList){this.childList[0].focus();}else{this.focus();}}
break;case DTNodeStatus_Loading:this._setStatusNode({title:this.tree.options.strings.loading,addClass:this.tree.options.classNames.nodeWait});break;case DTNodeStatus_Error:this._setStatusNode({title:this.tree.options.strings.loadError,addClass:this.tree.options.classNames.nodeError});break;default:throw"Bad LazyNodeStatus: '"+lts+"'.";}},_parentList:function(includeRoot,includeSelf){var l=[];var dtn=includeSelf?this:this.parent;while(dtn){if(includeRoot||dtn.parent)
l.unshift(dtn);dtn=dtn.parent;};return l;},getLevel:function(){var level=0;var dtn=this.parent;while(dtn){level++;dtn=dtn.parent;};return level;},isVisible:function(){var parents=this._parentList(true,false);for(var i=0;i<parents.length;i++)
if(!parents[i].bExpanded)return false;return true;},makeVisible:function(){var parents=this._parentList(true,false);for(var i=0;i<parents.length;i++)
parents[i]._expand(true);},focus:function(){this.makeVisible();try{$(this.span).find(">a").focus();}catch(e){}},isActive:function(){return(this.tree.activeNode===this);},activate:function(){var opts=this.tree.options;if(this.data.isStatusNode)
return;if(opts.onQueryActivate&&opts.onQueryActivate.call(this.span,true,this)==false)
return;if(this.tree.activeNode){if(this.tree.activeNode===this)
return;this.tree.activeNode.deactivate();}
if(opts.activeVisible)
this.makeVisible();this.tree.activeNode=this;if(opts.persist)
$.cookie(opts.cookieId+"-active",this.data.key,opts.cookie);$(this.span).addClass(opts.classNames.active);if(opts.onActivate)
opts.onActivate.call(this.span,this);},deactivate:function(){if(this.tree.activeNode===this){var opts=this.tree.options;if(opts.onQueryActivate&&opts.onQueryActivate.call(this.span,false,this)==false)
return;$(this.span).removeClass(opts.classNames.active);if(opts.persist){$.cookie(opts.cookieId+"-active","",opts.cookie);}
this.tree.activeNode=null;if(opts.onDeactivate)
opts.onDeactivate.call(this.span,this);}},_userActivate:function(){var activate=true;var expand=false;if(this.data.isFolder){switch(this.tree.options.clickFolderMode){case 2:activate=false;expand=true;break;case 3:activate=expand=true;break;}}
if(this.parent==null&&this.tree.options.minExpandLevel>0){expand=false;}
if(expand){this.toggleExpand();this.focus();}
if(activate){this.activate();}},_setSubSel:function(hasSubSel){if(hasSubSel){this.hasSubSel=true;$(this.span).addClass(this.tree.options.classNames.partsel);}else{this.hasSubSel=false;$(this.span).removeClass(this.tree.options.classNames.partsel);}},_fixSelectionState:function(){if(this.bSelected){this.visit(function(dtnode){dtnode.parent._setSubSel(true);dtnode._select(true,false,false);});var p=this.parent;while(p){p._setSubSel(true);var allChildsSelected=true;for(var i=0;i<p.childList.length;i++){var n=p.childList[i];if(!n.bSelected&&!n.data.isStatusNode){allChildsSelected=false;break;}}
if(allChildsSelected)
p._select(true,false,false);p=p.parent;}}else{this._setSubSel(false);this.visit(function(dtnode){dtnode._setSubSel(false);dtnode._select(false,false,false);});var p=this.parent;while(p){p._select(false,false,false);var isPartSel=false;for(var i=0;i<p.childList.length;i++){if(p.childList[i].bSelected||p.childList[i].hasSubSel){isPartSel=true;break;}}
p._setSubSel(isPartSel);p=p.parent;}}},_select:function(sel,fireEvents,deep){var opts=this.tree.options;if(this.data.isStatusNode)
return;if(this.bSelected==sel){return;}
if(fireEvents&&opts.onQuerySelect&&opts.onQuerySelect.call(this.span,sel,this)==false)
return;if(opts.selectMode==1&&this.tree.selectedNodes.length&&sel)
this.tree.selectedNodes[0]._select(false,false,false);this.bSelected=sel;this.tree._changeNodeList("select",this,sel);if(sel){$(this.span).addClass(opts.classNames.selected);if(deep&&opts.selectMode==3)
this._fixSelectionState();if(fireEvents&&opts.onSelect)
opts.onSelect.call(this.span,true,this);}else{$(this.span).removeClass(opts.classNames.selected);if(deep&&opts.selectMode==3)
this._fixSelectionState();if(fireEvents&&opts.onSelect)
opts.onSelect.call(this.span,false,this);}},isSelected:function(){return this.bSelected;},select:function(sel){return this._select(sel!=false,true,true);},toggleSelect:function(){return this.select(!this.bSelected);},_expand:function(bExpand){if(this.bExpanded==bExpand){return;}
var opts=this.tree.options;if(!bExpand&&this.getLevel()<opts.minExpandLevel){this.tree.logDebug("dtnode._expand(%o) forced expand - %o",bExpand,this);return;}
if(opts.onQueryExpand&&opts.onQueryExpand.call(this.span,bExpand,this)==false)
return;this.bExpanded=bExpand;this.tree._changeNodeList("expand",this,bExpand);this.render(false);if(this.bExpanded&&this.parent&&opts.autoCollapse){var parents=this._parentList(false,true);for(var i=0;i<parents.length;i++)
parents[i].collapseSiblings();}
if(opts.activeVisible&&this.tree.activeNode&&!this.tree.activeNode.isVisible()){this.tree.activeNode.deactivate();}
if(bExpand&&this.data.isLazy&&!this.isRead){try{this.tree.logDebug("_expand: start lazy - %o",this);this.setLazyNodeStatus(DTNodeStatus_Loading);if(true==opts.onLazyRead.call(this.span,this)){this.setLazyNodeStatus(DTNodeStatus_Ok);this.tree.logDebug("_expand: lazy succeeded - %o",this);}}catch(e){this.setLazyNodeStatus(DTNodeStatus_Error);}
return;}
if(opts.fx){var duration=opts.fx.duration||200;$(">DIV",this.div).animate(opts.fx,duration);}else{var $d=$(">DIV",this.div);$d.toggle();}
if(opts.onExpand)
opts.onExpand.call(this.span,bExpand,this);},expand:function(flag){if(!this.childList&&!this.data.isLazy&&flag)
return;if(this.parent==null&&this.tree.options.minExpandLevel>0&&!flag)
return;this._expand(flag);},toggleExpand:function(){this.expand(!this.bExpanded);},collapseSiblings:function(){if(this.parent==null)
return;var ac=this.parent.childList;for(var i=0;i<ac.length;i++){if(ac[i]!==this&&ac[i].bExpanded)
ac[i]._expand(false);}},onClick:function(event){if($(event.target).hasClass(this.tree.options.classNames.expander)){this.toggleExpand();}else if($(event.target).hasClass(this.tree.options.classNames.checkbox)){this.toggleSelect();}else{this._userActivate();this.span.getElementsByTagName("a")[0].focus();}
return false;},onDblClick:function(event){},onKeydown:function(event){var handled=true;switch(event.which){case 107:case 187:if(!this.bExpanded)this.toggleExpand();break;case 109:case 189:if(this.bExpanded)this.toggleExpand();break;case 32:this._userActivate();break;case 8:if(this.parent)
this.parent.focus();break;case 37:if(this.bExpanded){this.toggleExpand();this.focus();}else if(this.parent&&(this.tree.options.rootVisible||this.parent.parent)){this.parent.focus();}
break;case 39:if(!this.bExpanded&&(this.childList||this.data.isLazy)){this.toggleExpand();this.focus();}else if(this.childList){this.childList[0].focus();}
break;case 38:var sib=this.prevSibling();while(sib&&sib.bExpanded)
sib=sib.childList[sib.childList.length-1];if(!sib&&this.parent&&(this.tree.options.rootVisible||this.parent.parent))
sib=this.parent;if(sib)sib.focus();break;case 40:var sib;if(this.bExpanded){sib=this.childList[0];}else{var parents=this._parentList(false,true);for(var i=parents.length-1;i>=0;i--){sib=parents[i].nextSibling();if(sib)break;}}
if(sib)sib.focus();break;default:handled=false;}
return!handled;},onKeypress:function(event){},onFocus:function(event){var opts=this.tree.options;if(event.type=="blur"||event.type=="focusout"){if(opts.onBlur)
opts.onBlur.call(this.span,this);if(this.tree.tnFocused)
$(this.tree.tnFocused.span).removeClass(opts.classNames.focused);this.tree.tnFocused=null;if(opts.persist){$.cookie(opts.cookieId+"-focus",null,$.extend({},opts.cookie));}}else if(event.type=="focus"||event.type=="focusin"){if(this.tree.tnFocused&&this.tree.tnFocused!==this){this.tree.logDebug("dtnode.onFocus: out of sync: curFocus: %o",this.tree.tnFocused);$(this.tree.tnFocused.span).removeClass(opts.classNames.focused);}
this.tree.tnFocused=this;if(opts.onFocus)
opts.onFocus.call(this.span,this);$(this.tree.tnFocused.span).addClass(opts.classNames.focused);if(opts.persist)
$.cookie(opts.cookieId+"-focus",this.data.key,opts.cookie);}},_postInit:function(){if(opts.onPostInit)
opts.onPostInit.call(this.span,this);},visit:function(fn,data,includeSelf){var n=0;if(includeSelf==true){if(fn(this,data)==false)
return 1;n++;}
if(this.childList)
for(var i=0;i<this.childList.length;i++)
n+=this.childList[i].visit(fn,data,true);return n;},remove:function(){if(this===this.tree.root)
return false;return this.parent.removeChild(this);},removeChild:function(tn){var ac=this.childList;if(ac.length==1){if(tn!==ac[0])
throw"removeChild: invalid child";return this.removeChildren();}
if(tn===this.tree.activeNode)
tn.deactivate();if(tn.bSelected)
this.tree._changeNodeList("select",tn,false);if(tn.bExpanded)
this.tree._changeNodeList("expand",tn,false);tn.removeChildren(true);this.div.removeChild(tn.div);for(var i=0;i<ac.length;i++){if(ac[i]===tn){this.childList.splice(i,1);delete tn;break;}}},removeChildren:function(recursive){var tree=this.tree;var ac=this.childList;if(ac){for(var i=0;i<ac.length;i++){var tn=ac[i];if(tn===tree.activeNode)
tn.deactivate();if(tn.bSelected)
this.tree._changeNodeList("select",tn,false);if(tn.bExpanded)
this.tree._changeNodeList("expand",tn,false);tn.removeChildren(true);this.div.removeChild(tn.div);delete tn;}
this.childList=null;if(!recursive){this._expand(false);this.isRead=false;this.render(false,false);}}},_addChildNode:function(dtnode){var tree=this.tree;var opts=tree.options;if(this.childList==null){this.childList=[];}else{$(this.childList[this.childList.length-1].span).removeClass(opts.classNames.lastsib);}
this.childList.push(dtnode);dtnode.parent=this;if(dtnode.data.expand||opts.minExpandLevel>=dtnode.getLevel())
this.bExpanded=true;if(!dtnode.data.isStatusNode&&opts.selectMode==3&&!tree.isInitializing())
dtnode._fixSelectionState();if(tree.bEnableUpdate)
this.render(true,true);return dtnode;},_addNode:function(data){return this._addChildNode(new DynaTreeNode(this,this.tree,data));},append:function(obj){if(!obj||obj.length==0)
return;if(!obj.length)
obj=[obj];var prevFlag=this.tree.enableUpdate(false);var tnFirst=null;for(var i=0;i<obj.length;i++){var data=obj[i];var dtnode=this._addNode(data);if(!tnFirst)tnFirst=dtnode;if(data.children)
dtnode.append(data.children);}
this.tree.enableUpdate(prevFlag);return tnFirst;},appendAjax:function(ajaxOptions){this.setLazyNodeStatus(DTNodeStatus_Loading);var self=this;var orgSuccess=ajaxOptions.success;var orgError=ajaxOptions.error;var options=$.extend({},this.tree.options.ajaxDefaults,ajaxOptions,{success:function(data,textStatus){self.append(data);self.setLazyNodeStatus(DTNodeStatus_Ok);if(orgSuccess)
orgSuccess.call(options,self);},error:function(XMLHttpRequest,textStatus,errorThrown){self.setLazyNodeStatus(DTNodeStatus_Error);if(orgError)
orgError.call(options,self,XMLHttpRequest,textStatus,errorThrown);}});$.ajax(options);},lastentry:undefined}
var DynaTree=Class.create();DynaTree.version="$Version: 0.4.2$";DynaTree.prototype={initialize:function(divContainer,options){this.options=options;this.bEnableUpdate=true;this._nodeCount=0;this.initMode="data";this.activeNode=null;this.selectedNodes=[];this.expandedNodes=[];if(this.options.persist){this.initActiveKey=$.cookie(this.options.cookieId+"-active");if(cookie||this.initActiveKey!=null)
this.initMode="cookie";this.initFocusKey=$.cookie(this.options.cookieId+"-focus");var cookie=$.cookie(this.options.cookieId+"-expand");if(cookie!=null)
this.initMode="cookie";this.initExpandedKeys=cookie?cookie.split(","):[];cookie=$.cookie(this.options.cookieId+"-select");this.initSelectedKeys=cookie?cookie.split(","):[];}
this.logDebug("initMode: %o, active: %o, focus: %o, expanded: %o, selected: %o",this.initMode,this.initActiveKey,this.initFocusKey,this.initExpandedKeys,this.initSelectedKeys);this.cache={tagEmpty:"<span class='"+options.classNames.empty+"'></span>",tagVline:"<span class='"+options.classNames.vline+"'></span>",tagExpander:"<span class='"+options.classNames.expander+"'></span>",tagConnector:"<span class='"+options.classNames.connector+"'></span>",tagNodeIcon:"<span class='"+options.classNames.nodeIcon+"'></span>",tagCheckbox:"<span class='"+options.classNames.checkbox+"'></span>",lastentry:undefined};this.divTree=divContainer;this.tnRoot=new DynaTreeNode(null,this,{title:this.options.title,key:"root"});this.tnRoot.data.isFolder=true;this.tnRoot.render(false,false);this.divRoot=this.tnRoot.div;this.divRoot.className=this.options.classNames.container;this.divTree.appendChild(this.divRoot);},toString:function(){return"DynaTree '"+this.options.title+"'";},toDict:function(){return this.tnRoot.toDict(true);},logDebug:function(msg){if(this.options.debugLevel>=2){Array.prototype.unshift.apply(arguments,["debug"]);_log.apply(this,arguments);}},logInfo:function(msg){if(this.options.debugLevel>=1){Array.prototype.unshift.apply(arguments,["info"]);_log.apply(this,arguments);}},logWarning:function(msg){Array.prototype.unshift.apply(arguments,["warn"]);_log.apply(this,arguments);},isInitializing:function(){return(this.initMode=="data"||this.initMode=="cookie"||this.initMode=="postInit");},_changeNodeList:function(mode,node,bAdd){if(!node)
return false;var cookieName=this.options.cookieId+"-"+mode;var nodeList=(mode=="expand")?this.expandedNodes:this.selectedNodes;var idx=$.inArray(node,nodeList);if(bAdd){if(idx>=0)
return false;nodeList.push(node);}else{if(idx<0)
return false;nodeList.splice(idx,1);}
if(this.options.persist){var keyList=$.map(nodeList,function(e,i){return e.data.key});$.cookie(cookieName,keyList.join(","),this.options.cookie);}else{}},redraw:function(){this.logDebug("dynatree.redraw()...");this.tnRoot.render(true,true);this.logDebug("dynatree.redraw() done.");},getRoot:function(){return this.tnRoot;},getNodeByKey:function(key){var el=document.getElementById(this.options.idPrefix+key);return(el&&el.dtnode)?el.dtnode:null;},getActiveNode:function(){return this.activeNode;},getSelectedNodes:function(stopOnParents){if(stopOnParents==true){var nodeList=[];this.tnRoot.visit(function(dtnode){if(dtnode.bSelected){nodeList.push(dtnode);return false;}});return nodeList;}else{return this.selectedNodes;}},activateKey:function(key){var dtnode=this.getNodeByKey(key);if(!dtnode){this.activeNode=null;return null;}
dtnode.focus();dtnode.activate();return dtnode;},selectKey:function(key,select){var dtnode=this.getNodeByKey(key);if(!dtnode)
return null;dtnode.select(select);return dtnode;},enableUpdate:function(bEnable){if(this.bEnableUpdate==bEnable)
return bEnable;this.bEnableUpdate=bEnable;if(bEnable)
this.redraw();return!bEnable;},visit:function(fn,data,includeRoot){return this.tnRoot.visit(fn,data,includeRoot);},_createFromTag:function(parentTreeNode,$ulParent){var self=this;$ulParent.find(">li").each(function(){var $li=$(this);var $liSpan=$li.find(">span:first");var title;if($liSpan.length){title=$liSpan.html();}else{title=$li.html();var iPos=title.search(/<ul/i);if(iPos>=0)
title=$.trim(title.substring(0,iPos));else
title=$.trim(title);}
var data={title:title,isFolder:$li.hasClass("folder"),isLazy:$li.hasClass("lazy"),expand:$li.hasClass("expanded"),select:$li.hasClass("selected"),activate:$li.hasClass("active"),focus:$li.hasClass("focused")};if($li.attr("title"))
data.tooltip=$li.attr("title");if($li.attr("id"))
data.key=$li.attr("id");if($li.attr("data")){var dataAttr=$.trim($li.attr("data"));if(dataAttr){if(dataAttr.charAt(0)!="{")
dataAttr="{"+dataAttr+"}"
try{$.extend(data,eval("("+dataAttr+")"));}catch(e){throw("Error parsing node data: "+e+"\ndata:\n'"+dataAttr+"'");}}}
childNode=parentTreeNode._addNode(data);var $ul=$li.find(">ul:first");if($ul.length){self._createFromTag(childNode,$ul);}});},lastentry:undefined};$.widget("ui.dynatree",{init:function(){return this._init();},_init:function(){logMsg("Dynatree._init(): version='%s', debugLevel=%o.",DynaTree.version,this.options.debugLevel);this.options.event+=".dynatree";var $this=this.element;var opts=this.options;if(!opts.imagePath){$("script").each(function(){if(this.src.search(/.*dynatree[^/]*\.js$/i)>=0){if(this.src.indexOf("/")>=0)
opts.imagePath=this.src.slice(0,this.src.lastIndexOf("/"))+"/skin/";else
opts.imagePath="skin/";logMsg("Guessing imagePath from '%s': '%s'",this.src,opts.imagePath);return false;}});}
var divContainer=$this.get(0);if(opts.children||(opts.initAjax&&opts.initAjax.url)||opts.initId)
$(divContainer).empty();this.tree=new DynaTree(divContainer,opts);var root=this.tree.getRoot();var prevFlag=this.tree.enableUpdate(false);this.tree.logDebug("Start init tree structure...");if(opts.children){root.append(opts.children);}else if(opts.initAjax&&opts.initAjax.url){root.appendAjax(opts.initAjax);}else if(opts.initId){this.tree._createFromTag(root,$("#"+opts.initId));}else{var $ul=$this.find(">ul").hide();this.tree._createFromTag(root,$ul);$ul.remove();}
this.tree.enableUpdate(prevFlag);this.tree.logDebug("Init tree structure... done.");this.bind();this.tree.initMode="postInit";nodeList=this.tree.selectedNodes.slice();this.tree.selectedNodes=[];for(var i=0;i<nodeList.length;i++){var dtnode=nodeList[i];this.tree.logDebug("Re-select on init: %o",dtnode);dtnode.bSelected=false;dtnode.select(true);}
if(this.tree.focusNode){this.tree.logDebug("Focus on init: %o",this.tree.focusNode);this.tree.focusNode.focus();}
if(this.tree.activeNode){var dtnode=this.tree.activeNode;this.tree.activeNode=null;this.tree.logDebug("Activate on init: %o",dtnode);dtnode._userActivate();}
this.tree.initMode="running";},bind:function(){var $this=this.element;var o=this.options;this.unbind();function __getNodeFromElement(el){var iMax=4;do{if(el.dtnode)return el.dtnode;el=el.parentNode;}while(iMax--);return null;}
$this.bind("click.dynatree dblclick.dynatree keypress.dynatree keydown.dynatree",function(event){var dtnode=__getNodeFromElement(event.target);if(!dtnode)
return false;dtnode.tree.logDebug("bind(%o): dtnode: %o",event,dtnode);switch(event.type){case"click":return(o.onClick&&o.onClick(dtnode,event)===false)?false:dtnode.onClick(event);case"dblclick":return(o.onDblClick&&o.onDblClick(dtnode,event)===false)?false:dtnode.onDblClick(event);case"keydown":return(o.onKeydown&&o.onKeydown(dtnode,event)===false)?false:dtnode.onKeydown(event);case"keypress":return(o.onKeypress&&o.onKeypress(dtnode,event)===false)?false:dtnode.onKeypress(event);};});function __focusHandler(event){event=arguments[0]=$.event.fix(event||window.event);var dtnode=__getNodeFromElement(event.target);return dtnode?dtnode.onFocus(event):false;}
var div=this.tree.divTree;if(div.addEventListener){div.addEventListener("focus",__focusHandler,true);div.addEventListener("blur",__focusHandler,true);}else{div.onfocusin=div.onfocusout=__focusHandler;}},unbind:function(){this.element.unbind(".dynatree");},enable:function(){this.bind();this.setData("disabled",false);},disable:function(){this.unbind();this.setData("disabled",true);},getTree:function(){return this.tree;},getRoot:function(){return this.tree.getRoot();},getActiveNode:function(){return this.tree.getActiveNode();},getSelectedNodes:function(){return this.tree.getSelectedNodes();},lastentry:undefined});$.ui.dynatree.getter="getTree getRoot getActiveNode getSelectedNodes";$.ui.dynatree.defaults={title:"Dynatree root",rootVisible:false,minExpandLevel:1,imagePath:null,children:null,initId:null,initAjax:null,autoFocus:true,keyboard:true,persist:false,autoCollapse:false,clickFolderMode:3,activeVisible:true,checkbox:false,selectMode:2,fx:null,onClick:null,onDblClick:null,onKeydown:null,onKeypress:null,onFocus:null,onBlur:null,onQueryActivate:null,onQuerySelect:null,onQueryExpand:null,onActivate:null,onDeactivate:null,onSelect:null,onExpand:null,onLazyRead:null,ajaxDefaults:{cache:false,dataType:"json"},strings:{loading:"Loading&#8230;",loadError:"Load error!"},idPrefix:"ui-dynatree-id-",cookieId:"ui-dynatree-cookie",cookie:{expires:null},classNames:{container:"ui-dynatree-container",folder:"ui-dynatree-folder",document:"ui-dynatree-document",empty:"ui-dynatree-empty",vline:"ui-dynatree-vline",expander:"ui-dynatree-expander",connector:"ui-dynatree-connector",checkbox:"ui-dynatree-checkbox",nodeIcon:"ui-dynatree-icon",nodeError:"ui-dynatree-statusnode-error",nodeWait:"ui-dynatree-statusnode-wait",hidden:"ui-dynatree-hidden",combinedExpanderPrefix:"ui-dynatree-exp-",combinedIconPrefix:"ui-dynatree-ico-",active:"ui-dynatree-active",selected:"ui-dynatree-selected",expanded:"ui-dynatree-expanded",lazy:"ui-dynatree-lazy",focused:"ui-dynatree-focused",partsel:"ui-dynatree-partsel",lastsib:"ui-dynatree-lastsib"},debugLevel:1,lastentry:undefined};$.ui.dynatree.nodedatadefaults={title:null,key:null,isFolder:false,isLazy:false,tooltip:null,icon:null,addClass:null,activate:false,focus:false,expand:false,select:false,children:null,lastentry:undefined};})(jQuery);