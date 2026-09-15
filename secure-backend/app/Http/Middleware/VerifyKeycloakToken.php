<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;
use Firebase\JWT\JWT;
use Firebase\JWT\JWK;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;

class VerifyKeycloakToken
{
    /**
     * Handle an incoming request.
     *
     * @param  Closure(Request): (Response)  $next
     */
    public function handle(Request $request, Closure $next): Response
{
    $authHeader = $request->header('Authorization');

    if (!$authHeader || !str_starts_with($authHeader, 'Bearer ')) {
        return response()->json(['message' => 'Missing or malformed Authorization header'], 401);
    }

    $token = substr($authHeader, 7);

    try {
        $jwks = Cache::remember('keycloak_jwks', 3600, function () {
            $response = Http::get(config('services.keycloak.jwks_url'));
            return $response->json();
        });

        $decoded = JWT::decode($token, JWK::parseKeySet($jwks));

    } catch (\Exception $e) {
        return response()->json(['message' => 'Invalid or expired token', 'error' => $e->getMessage()], 401);
    }

    $request->attributes->set('jwt_username', $decoded->preferred_username);
    $request->attributes->set('jwt_roles', $decoded->realm_access->roles ?? []);

return $next($request);
}
}
