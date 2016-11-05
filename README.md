# BackMenu
## 带有滚动视图的前后切换

主要实现当主要界面是滚动视图，想在滚动视图到顶时继续滑动出现隐藏的内容视图

## Demo1实现思路

 * 思路：

 1. 两个scrollView嵌套
 2. 当前面的scrollView滑到顶部，无法再滑动，不会监听滑动，而是传递到后面的ScrollView上
 3. 将后面显示的内容放到后面scrollView的contentInset区域
 4. 当后面scrollView监听到didScroll事件时，根据偏移量判断：如果后面的内容出现了，禁用前面scrollView的scrollEnabeld，保证后面显示内容出现时，再滑动前面scrollView时还是运行后面scrollView的事件，能滑动回去，而不是滑动前面scrollView的内容；当后面的内容完全被前面的scrollView覆盖时，启用前面的scrollView的可滑动

 * 效果

<img src="scroll.gif" height="400"/>



  


