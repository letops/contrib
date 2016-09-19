// Obtained and modified from:
// https://goo.gl/gTzHJo

var React = require('react');
var PropTypes = React.PropTypes;

// Typeform component that renders each component of a form
var typeForm = React.createClass({
  propTypes: {
    children: PropTypes.arrayOf(PropTypes.element).isRequired,
    tfShowClass: PropTypes.string,
    tfHideClass: PropTypes.string,
    onSubmit: PropTypes.func,
    onEndShow: PropTypes.bool,
    submitBtnText: PropTypes.string,
    submitBtnClass: PropTypes.string,
    nextBtnText: PropTypes.string,
    prevBtnText: PropTypes.string,
    nextBtnClass: PropTypes.string,
    prevBtnClass: PropTypes.string,
    nextBtnOnClick: PropTypes.func,
    prevBtnOnClick: PropTypes.func,
  },

  getDefaultProps: function () {
    return {
      tfShowClass: 'fade-in-up',
      tfHideClass: 'fade-out-up',
      onSubmit: function (event) {
        event.preventDefault();
      },

      onEndShow: false,
      submitBtnText: 'Save',
      prevBtnText: 'Prev',
      nextBtnText: 'Next',
      nextBtnOnClick: function () { ; },
      prevBtnOnClick: function () { ; },
    };
  },

  getInitialState: function () {
    return {
      current: 0,
    };
  },

  //  * Set className for component to show/hide
  setClass: function (element, tfClass) {
    return React.cloneElement(element, {
      tfClass: tfClass,
    });
  },

  // Increment State counter
  incState: function (event) {
    event.preventDefault();
    if (this.state.current < this.props.children.length) {
      var current = this.state.current + 1;
      this.setState({ current: current, });
    }

    this.props.nextBtnOnClick();
  },

  decState: function () {
    if (this.state.current > 0) {
      var current = this.state.current - 1;
      this.setState({ current: current, });
    }

    this.props.prevBtnOnClick();
  },

  // Get the current component to show on screen
  renderChildren: function (children) {
    var childrenLength = this.props.children.length;
    var allChildren = React.Children.map(children, function (child, index) {
      var tfClass = (index == this.state.current ||
                     (this.props.onEndShow && this.state.current == childrenLength - 1))
        ? tfClass = this.props.tfShowClass
        : tfClass = this.props.tfHideClass;

      var prevOrNullButton = (index > 0)
        ? <button onClick={ this.decState } className={ this.props.prevBtnClass }
           >{ this.props.prevBtnText }</button>
        : null;

      var nextOrNullButton = (index < (childrenLength - 1))
        ? <button type='submit' onClick={ this.incState } className={ this.props.nextBtnClass }
          >{ this.props.nextBtnText }</button>
        : null;

      return (
        <form key={ index } className={ 'animated ' + tfClass } action=''
          onSubmit={ (index == childrenLength - 1) ? this.props.onSubmit : this.incState }>
          { child }
          { prevOrNullButton }
          { nextOrNullButton }
        </form>
      );

    }.bind(this));

    return allChildren;
  },

  // render the typeform
  render: function () {
    var progressWidth = (this.state.current / (this.props.children.length - 1)) * 100.0;
    var buttonShowClass = (this.state.current == this.props.children.length - 1)
      ? ' show'
      : ' hide';
    return (
      <div className='typeform-container'>
        { this.renderChildren(this.props.children) }

        <div className='progress-cont'>
          <div className='progress' style={{ width: progressWidth + '%', }}></div>
        </div>

        <button onClick={ this.props.onSubmit }
          className={ this.props.submitBtnClass + buttonShowClass }
          >{ this.props.submitBtnText }
        </button>
      </div>
    );
  },
});

module.exports = typeForm;
