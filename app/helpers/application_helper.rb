module ApplicationHelper
  def is_fishy(params)
    # Prefer wildcard-captured unmatched path; fall back to current request path
    path = params[:unmatched] || (respond_to?(:request) ? request.path.to_s : "")
    format = params[:format]
    invalid_paths = [ "phpinfo", "cgi-bin", "bins", "geoserver", "webui", "geoip", "boaform", "actuator/health", "developmentserver/metadatauploader", "manager/html" ]
    invalid_formats = [ "html", "php", "env", "git", "envrc", "old", "log" ]
    invalid_formats_with_dot = invalid_formats.map { |s| ".#{s}" }
    invalid_formats.include?(format) || (invalid_paths + invalid_formats_with_dot).any? { |s| path.include?(s) }
  end
end
