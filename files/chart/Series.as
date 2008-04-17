﻿package {		import flash.display.Sprite;	import flash.filters.DropShadowFilter;	import flash.events.MouseEvent;	import flash.external.ExternalInterface;		public class Series extends Sprite {				private var deletable:Boolean;		private var title:String;		private var items:Array;		private var label:SeriesLabel;		private var axes:Axes;		private var color:int;				public function Series(data:XML, deletable:Boolean, axes:Axes, index:int) {			this.deletable = deletable;			this.axes = axes;			initColor(index);			parseData(data);			initLabel();			filters = [new DropShadowFilter(2, 45, 0x000000, 0.25)];		}				private function initColor(index:int):void {			var colors:Array = [0xFF0000, 0x00FF00, 0x0000FF];			color = colors[index % 3];			color |= colors[(index + Math.floor(index / 3)) % 3];			if (index >= 9) color *= Math.random();		}				private function parseData(data:XML):void {			title = data.@title;			items = new Array();			for each (var item:XML in data.item) {				addItem(item);			}		}				private function initLabel():void {			label = new SeriesLabel(title, color);			label.addEventListener(MouseEvent.CLICK, onLabelClick);			label.visible = false;			addChild(label);		}				private function onLabelClick(event:MouseEvent):void {			dispatchEvent(new SeriesEvent(SeriesEvent.REMOVE, this));		}				public function isDeletable():Boolean {			return deletable;		}				public function draw():void {			if (items.length > 0) {				removeItems();				graphics.clear();				graphics.lineStyle(4, color);				addChild(items[0]);				items[0].draw(0);				graphics.moveTo(items[0].x, items[0].y);				var count:int = getCount();				for (var i:uint = 1; i <= count; i++) {					var item:Item = items[i];					addChild(item);					item.draw(i);					graphics.lineTo(item.x, item.y);				}				var maxPos:int = axes.getHorizontal().getWidth();				label.position(maxPos, items[0].y);				label.visible = true;			}		}				public function addItem(data:XML, isNew:Boolean = false):Item {			var item:Item = new Item(data, axes, color);			isNew ? items.unshift(item) : items.push(item);			return item;		}				private function removeItems():void {			for each (var item:Item in items) {				if (contains(item)) removeChild(item);			}		}				public function getItemCount():int {			return items.length;		}				public function hasItems():Boolean {			return items.length > 0;		}				public function getClosest():Item {			var count:int = getCount();			for (var i:uint = 0; i <= count; i++) {				items[i].deselect();			}			var indexes:Array = axes.getHorizontal().getClosestIndexes(mouseX);			if (indexes[1] >= items.length) {				return items[items.length - 1];			}			else {				var d1:int = Math.abs(mouseX - items[indexes[0]].x);				var d2:int = Math.abs(items[indexes[1]].x - mouseX);				return d1 < d2 ? items[indexes[0]] : items[indexes[1]];			}		}				private function getCount():int {			var count:int = axes.getHorizontal().getItemCount();			if (count >= items.length) count = items.length - 1;			return count;		}				public function getVerticalMin():int {			var min:int = 2147483647;			var count:int = getCount();			for (var i:int = 0; i <= count; i++) {				var v:int = items[i].getV();				if (v < min) min = v;			}			return min;		}				public function getVerticalMax():int {			var max:int = -2147483647;			var count:int = getCount();			for (var i:int = 0; i <= count; i++) {				var v:int = items[i].getV();				if (v > max) max = v;			}			return max;		}			}	}