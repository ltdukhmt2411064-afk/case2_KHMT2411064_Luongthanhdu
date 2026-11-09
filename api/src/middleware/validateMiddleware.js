const { validationResult } = require('express-validator');

const validateMiddleware = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    const formattedErrors = errors.array().map((err) => ({
      field: err.path || err.param,
      message: err.msg,
    }));

    return res.status(400).json({
      status: 'fail',
      message: formattedErrors[0].message,
      errors: formattedErrors,
    });
  }
  next();
};

module.exports = validateMiddleware;
