var React = require('react');
var PropTypes = React.PropTypes;
var IDGen = require('./IDGen');

var DRFInputRenderer = React.createClass({
  propTypes: {
    specs: PropTypes.any.isRequired,
    showLabel: PropTypes.bool,
    handler: PropTypes.func.isRequired,
    stateKey: PropTypes.string,
    value: PropTypes.any.isRequired,
    error: PropTypes.array,
  },

  getDefaultProps: function () {
    return {
      stateKey: '',
      showLabel: true,
      error: [],
    };
  },

  componentWillMount: function () {
    this.id = IDGen();
  },

  renderAsText: function () {
    return (
      <input id={ this.id } type='text'
        required={ this.props.specs.required }
        readOnly={ this.props.specs.read_only }
        value={ this.props.value }
        onChange={ this.props.handler.bind(null, this.props.stateKey) }/>
    );
  },

  renderAsInteger: function () {
    return (
      <input id={ this.id } type='number' step='1'
        required={ this.props.specs.required }
        readOnly={ this.props.specs.read_only }
        value={ this.props.value }
        onChange={ this.props.handler.bind(null, this.props.stateKey) }/>
    );
  },

  renderAsDecimal: function () {
    return (
      <input id={ this.id } type='number' step='0.1'
        required={ this.props.specs.required }
        readOnly={ this.props.specs.read_only }
        value={ this.props.value }
        onChange={ this.props.handler.bind(null, this.props.stateKey) }/>
    );
  },

  renderAsCheckbox: function () {
    return (
      <input id={ this.id } type='checkbox'
        required={ this.props.specs.required }
        readOnly={ this.props.specs.read_only }
        checked={ this.props.value }
        onChange={ this.props.handler.bind(null, this.props.stateKey) }/>
    );
  },

  renderAsSelect: function (multiple = false) {
    var options = this.props.specs.choices.map(function (choice, index) {
      if (typeof choice.value != 'string') {
        var opts = choice.value.map(function (opt, ind) {
          return (
            <option key={ ind + 1 } value={ opt.value }>{ opt.display_name }</option>
          );
        });

        return (
          <optgroup key={ i + 1 } label={ choice.display_name }
            >{ opts }</optgroup>
        );
      }

      return <option key={ index + 1 } value={ choice.value }
        >{ choice.display_name }</option>;
    }.bind(this));

    options.unshift(<option key={ 0 } disabled={ true } value=''>-----</option>);

    return (
      <select id={ this.id } required={ this.props.specs.required }
        multiple={ multiple }
        readOnly={ this.props.specs.read_only }
        value={ this.props.value }
        onChange={ this.props.handler.bind(null, this.props.stateKey) }>
        { options }
      </select>
    );
  },

  render: function () {
    var label = this.props.showLabel
      ? <label htmlFor={ this.id } className={
        (this.props.error.length > 0 ? 'error ' : '') +
      (this.props.specs.required ? 'required' : '') }>
        { this.props.specs.required && '* ' }{ this.props.specs.label }
      </label>
      : null;
    var input = null;
    switch (this.props.specs.type) {
      case 'multiple choice':
        input = this.renderAsSelect(true);
        break;
      case 'choice':
        input = this.renderAsSelect();
        break;
      case 'integer':
        input = this.renderAsInteger();
        break;
      case 'decimal':
        input = this.renderAsDecimal();
        break;
      case 'boolean':
        input = this.renderAsCheckbox();
        break;
      case 'datetime':
      case 'string':
      default:
        input = this.renderAsText();
        break;
    }
    var errors = this.props.error.map(function (err, index) {
      return (<span className='error' key={ index }>{ err }</span>);
    });

    return (
      <div className='drfinput'>
        { label }
        { input }
        { errors }
      </div>
    );
  },
});

module.exports = DRFInputRenderer;
